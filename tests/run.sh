#!/usr/bin/env bash
# tb tests. Builds a small fake Gradle project, swaps fzf for tests/fake-fzf (scripted key presses),
# then checks every command. No Gradle, Android SDK or terminal needed.
#   tests/run.sh
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TB=${TB:-$here/../tb}
T=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/tb-test.XXXXXX")" && pwd -P)   # real path: macOS temp dirs are symlinked
trap 'rm -rf "$T"' EXIT

export HOME=$T/home GRADLE_LOG=$T/gradle.log FAKE_FZF_SCRIPT=$T/fzf.script FAKE_FZF_LOG=$T/fzf.log
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
unset GB_STATE GB_CHANGED TB_INTERACTIVE
mkdir -p "$HOME" "$T/bin"
ln -s "$here/fake-fzf" "$T/bin/fzf"
export PATH="$T/bin:$PATH"
REPO=$T/repo
P="./gradlew --continue --parallel --console=rich"

passed=0 failed=0
ok() { passed=$((passed + 1)); echo "ok    $1"; }
bad() { failed=$((failed + 1)); echo "FAIL  $1"; shift; printf '      %s\n' "$@"; }
check() { # name expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected: $2" "actual:   $3"; fi
}
contains() { # name text needle
  if grep -qF -- "$3" <<< "$2"; then ok "$1"; else bad "$1" "missing: $3" "in: $(head -c 400 <<< "$2")"; fi
}
lacks() { # name text needle
  if grep -qF -- "$3" <<< "$2"; then bad "$1" "should not contain: $3"; else ok "$1"; fi
}

gb() { (cd "$REPO" && "$TB" "$@"); }
# Runs the menu with scripted key presses (see tests/fake-fzf), one per argument
tui() {
  printf '%s\n' "$@" > "$FAKE_FZF_SCRIPT"; : > "$FAKE_FZF_LOG"; : > "$GRADLE_LOG"
  (cd "$REPO" && TB_INTERACTIVE=1 "$TB" < /dev/null)
}
gradle_runs() { grep -v '^-q projects$' "$GRADLE_LOG" || true; }

# --- the fake project: :app, :lib:a (changed on this branch), :lib:b (screenshot test)
mkdir -p "$REPO" && cd "$REPO"
git init -q -b main
cat > gradlew <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$GRADLE_LOG"
if [ "$*" = "-q projects" ]; then
  [ -z "${GRADLE_FAIL:-}" ] || exit 1
  printf "Root project 'demo'\n+--- Project ':app'\n+--- Project ':lib'\n|    +--- Project ':lib:a'\n|    \\\\--- Project ':lib:b'\n\\\\--- Project ':generated'\n"
fi
EOF
chmod +x gradlew
printf "include ':app'\ninclude ':lib:a'\ninclude ':lib:b'\n" > settings.gradle
mkdir -p app/src/main lib/a/src/main lib/a/src/test/java lib/b/src/test/java
echo x > app/src/main/App.kt
echo x > lib/a/src/main/A.kt
echo 'class ATest' > lib/a/src/test/java/ATest.kt
echo 'class BTest' > lib/b/src/test/java/BTest.kt
echo 'class BScreenshotTest { val paparazzi = Paparazzi() }' > lib/b/src/test/java/BScreenshotTest.kt
# dependencies: :lib:a and :app use :lib:b, :generated uses :app (the commented one doesn't count)
printf "dependencies {\n    testImplementation project(path: ':lib:b')\n}\n" > lib/a/build.gradle
printf 'dependencies {\n    implementation(projects.lib.b)\n    // implementation(project(":lib:a"))\n}\n' > app/build.gradle.kts
mkdir -p generated && printf 'dependencies { implementation(project(":app")) }\n' > generated/build.gradle.kts
cat > .tb <<'EOF'
# step | label | task | where | auto
4 | Unit tests                | testDebugUnitTest    | module | auto
4 | Screenshot tests: verify  | verifyPaparazziDebug | module
3 | Detekt (static analysis)  | detekt               | root   | auto
2 | Ktlint: fix formatting    | ktlintFormat         | root
5 | Build debug APK           | assembleDebug        | :app
1 | Clean                     | clean                | root
EOF
git add -A && git commit -qm init
git checkout -qb work
echo y >> lib/a/src/main/A.kt
cd - > /dev/null

echo "== without a terminal"
out=$(gb < /dev/null)
contains "plain tb prints help instead of waiting for input" "$out" "tb print SPEC"
contains "help names the command list it uses" "$out" "$REPO/.tb"

echo "== help"
out=$(gb -h)
contains "help says what tb is" "$out" "a task board for Gradle"
contains "help puts Auto first, on changed modules" "$out" "★ Auto     the main path: finds the modules changed on your branch"
contains "help says Auto runs the tools marked auto" "$out" 'marked "auto" in .tb'
contains "help mentions picking by hand" "$out" "its modules and its test classes"
contains "help lists the menu keys" "$out" "ENTER open/tick · TAB tick several · ESC back/quit · DEL delete preset"
for sub in print run list modules changed presets history last hist init refresh agents help; do
  contains "help lists tb $sub" "$out" "  tb $sub "
done
contains "help explains SPEC" "$out" "task=:a,:b"
contains "help shows the runner in use" "$out" "Runner: $P"
check "help is short" "yes" "$([ "$(wc -l <<< "$out")" -le 45 ] && echo yes || echo no)"
check "--help and help print the same" "$out" "$(gb --help)"
check "help and -h print the same" "$out" "$(gb help)"

echo "== modules"
rm -rf "$HOME/.cache/tb"; : > "$GRADLE_LOG"
check "modules come from gradle, including ones not in settings" \
  "$(printf ':app\n:lib\n:lib:a\n:lib:b\n:generated')" "$(gb modules)"
gb modules > /dev/null
check "module list is cached" "1" "$(grep -c projects "$GRADLE_LOG")"
gb refresh > /dev/null
check "refresh asks gradle again" "2" "$(grep -c projects "$GRADLE_LOG")"
echo "include ':lib:c'" >> "$REPO/settings.gradle"
gb modules > /dev/null
check "changing settings re-reads the modules" "3" "$(grep -c projects "$GRADLE_LOG")"
(cd "$REPO" && git checkout -q settings.gradle)
check "falls back to settings includes when gradle fails" \
  "$(printf ':app\n:lib:a\n:lib:b')" "$(GRADLE_FAIL=1 gb refresh > /dev/null; GRADLE_FAIL=1 gb modules)"
gb refresh > /dev/null
check "changed lists modules touched on this branch" ":lib:a" "$(gb changed)"

echo "== list"
out=$(gb list)
check "list starts with the default gradle runner" "runner: $P" "$(sed -n 1p <<< "$out")"
contains "list shows tasks with their step and where they run" "$out" "4     testDebugUnitTest          module   auto  Unit tests"
contains "list shows fixed-module tasks" "$out" "5     assembleDebug              :app     -     Build debug APK"

echo "== print"
check "runs by step whatever the order; steps 1-2 are their own build" \
  "$P clean ktlintFormat && $P detekt :lib:a:testDebugUnitTest" \
  "$(gb print testDebugUnitTest=changed detekt clean ktlintFormat)"
check "module names work without the leading colon" \
  "$P :lib:a:verifyPaparazziDebug :lib:b:verifyPaparazziDebug" "$(gb print verifyPaparazziDebug=lib:a,:lib:b)"
check "=ALL runs the task on every module" "$P testDebugUnitTest" "$(gb print testDebugUnitTest=ALL)"
check "fixed-module tasks get their module" "$P :app:assembleDebug" "$(gb print assembleDebug)"
check "auto adds the auto checks on changed modules" "$P detekt :lib:a:testDebugUnitTest" "$(gb print auto)"
check "tasks not in the list pass through" "$P detekt :app:bundleRelease" "$(gb print :app:bundleRelease detekt)"
check "the same task twice is added once" "$P detekt" "$(gb print detekt detekt)"
check "a module task twice runs on both sets of modules" "$P :lib:a:testDebugUnitTest :lib:b:testDebugUnitTest" \
  "$(gb print testDebugUnitTest=:lib:a testDebugUnitTest=:lib:b)"

echo "== mistakes say what's wrong and exit 1"
out=$(gb print testDebugUnitTest 2>&1); rc=$?
check "per-module task without modules: exit 1" "1" "$rc"
contains "per-module task without modules: explains" "$out" "testDebugUnitTest=:module"
out=$(gb print testDebugUnitTest=:nope 2>&1); rc=$?
check "unknown module: exit 1" "1" "$rc"; contains "unknown module: named" "$out" "No module :nope"
out=$(gb print @nope 2>&1); rc=$?
check "unknown preset: exit 1" "1" "$rc"
out=$(gb bogus 2>&1); rc=$?
check "unknown command: exit 1" "1" "$rc"; contains "unknown command: named" "$out" 'unknown command "bogus"'
out=$(gb print 2>&1); rc=$?
check "print with nothing to print: exit 1" "1" "$rc"
out=$(gb run 2>&1); rc=$?
check "run with nothing to run: exit 1" "1" "$rc"
contains "and shows the help" "$out" "tb print SPEC"
out=$(gb print @nope 2>&1)
contains "unknown preset: named" "$out" 'No preset "nope"'

echo "== nothing changed on the branch"
(cd "$REPO" && git stash -q)
check "changed is empty" "" "$(gb changed)"
out=$(gb print testDebugUnitTest=changed 2>&1); rc=$?
check "=changed with nothing changed: exit 1" "1" "$rc"; contains "=changed with nothing changed: explains" "$out" "No modules changed"
out=$(gb print auto 2>&1); rc=$?
check "auto with nothing changed adds nothing: exit 1" "1" "$rc"
contains "and warns there are no changed modules" "$out" "No changed modules found"
(cd "$REPO" && git stash pop -q)
check "changed is back" ":lib:a" "$(gb changed)"
(cd "$REPO" && git -c user.name=t -c user.email=t@t commit -qam "work on a")
check "changes committed on the branch count too" ":lib:a" "$(gb changed)"
contains "and auto uses them" "$(gb print auto 2>/dev/null)" ":lib:a:testDebugUnitTest"
(cd "$REPO" && git reset -q HEAD~1)

echo "== affected: changed modules and the modules that depend on them"
check "nothing depends on :lib:a, so affected is just :lib:a" ":lib:a" "$(gb affected)"
(cd "$REPO" && echo y >> lib/b/src/test/java/BTest.kt)
check "changed: :lib:a and :lib:b" "$(printf ':lib:a\n:lib:b')" "$(gb changed)"
check "affected follows project(path:), projects.x accessors and dependents of dependents" \
  "$(printf ':app\n:generated\n:lib:a\n:lib:b')" "$(gb affected)"
check "auto runs on the affected modules" \
  "$P detekt :app:testDebugUnitTest :generated:testDebugUnitTest :lib:a:testDebugUnitTest :lib:b:testDebugUnitTest" "$(gb print auto)"
check "=affected works in a SPEC" "$P :app:testDebugUnitTest :generated:testDebugUnitTest :lib:a:testDebugUnitTest :lib:b:testDebugUnitTest" \
  "$(gb print testDebugUnitTest=affected)"
check "=changed stays the changed modules only" "$P :lib:a:testDebugUnitTest :lib:b:testDebugUnitTest" \
  "$(gb print testDebugUnitTest=changed)"
tui "pick Unit tests" "pick ◆ CHANGED AND DEPENDENT" "esc" "pick ▶ Run" "pick Confirm" > /dev/null
check "modules screen: one row for the changed and dependent modules" \
  ":app:testDebugUnitTest :generated:testDebugUnitTest :lib:a:testDebugUnitTest :lib:b:testDebugUnitTest" "$(gradle_runs | sed 's/^--continue --parallel --console=rich //')"
contains "it shows how many" "$(cat "$FAKE_FZF_LOG")" "◆ CHANGED AND DEPENDENT MODULES (4)"
contains "dependents have a ☆" "$(cat "$FAKE_FZF_LOG")" "☆ :app"
contains "CTRL-A ticks every row shown" "$(cat "$FAKE_FZF_LOG")" "--bind=ctrl-a:select-all"
rm -f "$HOME/.tb_history"
(cd "$REPO" && git checkout -q lib/b/src/test/java/BTest.kt)

echo "== run, history, last, hist"
out=$(gb last 2>&1); rc=$?
check "last with nothing run yet: exit 1" "1" "$rc"; contains "and says so" "$out" "Nothing run here yet"
check "history starts empty" "" "$(gb history)"
: > "$GRADLE_LOG"
gb run detekt assembleDebug > /dev/null
check "run calls gradle with the command" "--continue --parallel --console=rich detekt :app:assembleDebug" "$(gradle_runs)"
check "history keeps it" "$P detekt :app:assembleDebug" "$(gb history)"
: > "$GRADLE_LOG"; gb last > /dev/null
check "last runs it again" "--continue --parallel --console=rich detekt :app:assembleDebug" "$(gradle_runs)"
gb run clean > /dev/null
check "history lists each command once, newest last" "$(printf '%s\n' "$P detekt :app:assembleDebug" "$P clean")" "$(gb history)"
gb last > /dev/null; gb run detekt assembleDebug > /dev/null
check "a command run again moves to the end" "$(printf '%s\n' "$P clean" "$P detekt :app:assembleDebug")" "$(gb history)"
printf '%s\n' "pick detekt" > "$FAKE_FZF_SCRIPT"; : > "$FAKE_FZF_LOG"; : > "$GRADLE_LOG"
gb hist > /dev/null
check "hist runs the picked command" "--continue --parallel --console=rich detekt :app:assembleDebug" "$(gradle_runs)"
check "hist lists newest first" "$P detekt :app:assembleDebug" "$(sed -n 2p "$FAKE_FZF_LOG")"
printf 'esc\n' > "$FAKE_FZF_SCRIPT"; : > "$GRADLE_LOG"
gb hist > /dev/null; rc=$?
check "hist with ESC runs nothing" "0/" "$rc/$(gradle_runs)"

echo "== init and agents"
(cd "$REPO" && mv .tb .tb.keep)
out=$(gb init); contains "init writes .tb" "$out" "Wrote $REPO/.tb"
contains "the written list explains itself to agents" "$(cat "$REPO/.tb")" "AI agents"
out=$(gb init 2>&1); rc=$?
check "init never overwrites" "1" "$rc"
contains "the written list mentions the optional runner line" "$(cat "$REPO/.tb")" "# runner: ./gradlew --continue --parallel --console=rich"
check "the commented runner line changes nothing" "runner: $P" "$(gb list | sed -n 1p)"
(cd "$REPO" && mv .tb.keep .tb)
out=$(gb agents)
contains "agents prints a note for AGENTS.md" "$out" "tb print"
contains "agents: tb run auto is the first choice" "$out" "First choice: \`tb run auto\`"
contains "agents: tb print auto shows the command" "$out" "\`tb print auto\` shows the command"
contains "agents: task names live in .tb" "$out" "listed in \`.tb\` (\`tb list\` shows them)"
contains "agents: don't guess gradle task names" "$out" "don't guess Gradle task names"

echo "== in-menu ticks (fzf callbacks)"
export GB_STATE=$T/state GB_CHANGED=":lib:a"; : > "$GB_STATE"
out=$(FZF_SELECT_COUNT=0 gb __enter cmd detekt root)
contains "ticking a whole-project command reloads in place" "$out" "reload-sync("
contains "the cursor stays on the ticked row" "$out" "+pos(6)+"
check "the tick is saved" "detekt" "$(cut -f1 "$GB_STATE")"
FZF_SELECT_COUNT=0 gb __enter cmd detekt root > /dev/null
check "ticking again removes it" "" "$(cut -f1 "$GB_STATE")"
check "per-module commands open their screen" "accept" "$(FZF_SELECT_COUNT=0 gb __enter cmd testDebugUnitTest module)"
check "with TAB ticks, enter accepts them all" "accept" "$(FZF_SELECT_COUNT=2 gb __enter cmd detekt root)"
check "header is 5 lines with nothing ticked" "5" "$(gb __header | wc -l | tr -d ' ' | awk '{print $1+1}')"
contains "header starts with the bare gradle line" "$(gb __header)" "$P"
FZF_SELECT_COUNT=0 gb __enter cmd clean root > /dev/null; FZF_SELECT_COUNT=0 gb __enter cmd detekt root > /dev/null
check "header is still 5 lines with two builds" "5" "$(gb __header | wc -l | tr -d ' ' | awk '{print $1+1}')"
contains "second build is shown on its own line" "$(gb __header)" "then $P detekt"
unset GB_STATE GB_CHANGED

echo "== menu"
tui "pick Unit tests" "pickall :lib:a$" "pick ATest" "pick ▶ Run" "pick Confirm" > /dev/null
check "command, module, test class, run" \
  "--continue --parallel --console=rich :lib:a:testDebugUnitTest --tests *.ATest" "$(gradle_runs)"

tui "pick Unit tests" "pickall :lib:b$" "pickall Test" "pick ▶ Run" "pick Confirm" > /dev/null
check "screenshot test classes are only given to unit tests that own them" \
  "--continue --parallel --console=rich :lib:b:testDebugUnitTest --tests *.BScreenshotTest --tests *.BTest" "$(gradle_runs)"

tui "pick Screenshot tests" "pickall :lib:b$" "pickall Test" "pick ▶ Run" "pick Confirm" > /dev/null
check "screenshot tasks only get screenshot test classes" \
  "--continue --parallel --console=rich :lib:b:verifyPaparazziDebug --tests *.BScreenshotTest" "$(gradle_runs)"

tui "pick Detekt" "pick Build debug" "pick Clean" "pick Ktlint" "pick ▶ Run" "pick Confirm" > /dev/null
check "ticked in any order, runs in the right order" \
  "$(printf -- '--continue --parallel --console=rich clean ktlintFormat\n--continue --parallel --console=rich detekt :app:assembleDebug')" \
  "$(gradle_runs)"

tui "pick ★ Auto" "pick ▶ Run" "pick Confirm" > /dev/null
check "auto, then run" "--continue --parallel --console=rich detekt :lib:a:testDebugUnitTest" "$(gradle_runs)"

tui "pick Detekt" "pick ▶ Run" "pick Cancel" "esc" > /dev/null
check "cancel runs nothing" "" "$(gradle_runs)"

tui "pick ▶ Run" "esc" > /dev/null
check "run with nothing ticked runs nothing" "" "$(gradle_runs)"
contains "and says why" "$(cat "$FAKE_FZF_LOG")" "Tick a command first"

tui "pick Unit tests" "pickall :lib:a$" "esc" "pick Unit tests" "esc" "esc" > /dev/null
contains "reopening a command starts with its modules ticked" "$(cat "$FAKE_FZF_LOG")" "+toggle"
contains "and offers to remove it" "$(cat "$FAKE_FZF_LOG")" "Remove Unit tests from the list"

contains "and fzf loads the rows before ticking them (--sync)" "$(grep -F -- '+toggle' "$FAKE_FZF_LOG")" "--sync"

tui "pick Unit tests" "pickall :lib:a$|:lib:b$" "pick ATest" "esc" > /dev/null
contains "a test command lists only the modules that own a picked class" "$(cat "$FAKE_FZF_LOG")" "✓ Unit tests  → :lib:a · 1 test class"

tui "pickall Unit tests|Screenshot tests" "pickall :lib:b$" "pickall Test" "pick ▶ Run" "pick Confirm" > /dev/null
check "unit and screenshot tests on one module share their test classes (one build runs the test task once)" \
  "--continue --parallel --console=rich :lib:b:testDebugUnitTest --tests *.BScreenshotTest --tests *.BTest :lib:b:verifyPaparazziDebug --tests *.BScreenshotTest --tests *.BTest" \
  "$(gradle_runs)"
tui "pick Unit tests" "pickall :lib:b$" "pick BTest" "pick Screenshot tests" "pickall :lib:b$" "pick ◆ ALL tests" "pick ▶ Run" "pick Confirm" > /dev/null
check "and if one of them runs all tests, both do" \
  "--continue --parallel --console=rich :lib:b:testDebugUnitTest :lib:b:verifyPaparazziDebug" "$(gradle_runs)"

tui "pick Unit tests" "pickall :lib:b$" "pick BTest" "pick ★ Auto" "pick ▶ Run" "pick Confirm" > /dev/null
check "Auto after picking a test class still runs all tests in the modules it adds" \
  "--continue --parallel --console=rich detekt :lib:b:testDebugUnitTest --tests *.BTest :lib:a:testDebugUnitTest" "$(gradle_runs)"

COLUMNS=60 tui "pick Detekt" "pick Build debug" "pick Clean" "pick Ktlint" "pick ▶ Run" "pick Cancel" "esc" > /dev/null
check "the run screen cuts a long command into lines that fit" "yes" \
  "$(awk '/--prompt=run\? >/ { f=1 } f && /^  / { n++ } END { print (n >= 1 ? "yes" : "no") }' "$FAKE_FZF_LOG")"

tui "pick Unit tests" "pickall :lib:a$" "esc" "pick Unit tests" "pick ✖ Remove" "pick ▶ Run" "esc" > /dev/null
check "removing a command takes it off the list" "" "$(gradle_runs)"

big=$T/big.tb; cp "$REPO/.tb" "$big.keep"; cp "$REPO/.tb" "$big"
for i in $(seq 1 400); do echo "4 | Filler command number $i with a long label to fill the pipe buffer quickly ........ | filler$i | root" >> "$big"; done
cp "$big" "$REPO/.tb"
out=$(tui "pick ★ Auto" "esc" 2>&1); rc=$?
check "a long menu does not crash after Auto (broken pipe)" "0" "$rc"
lacks "no broken pipe message" "$out" "Broken pipe"
cp "$big.keep" "$REPO/.tb"

echo "== presets"
tui "pick Detekt" "pick Clean" "pick 💾 Save" "query nightly" "esc" > /dev/null
preset=$HOME/.config/tb/presets/repo/nightly
check "save writes the preset" "clean detekt" "$(cut -f1 "$preset" | sort | tr '\n' ' ' | sed 's/ $//')"
contains "presets lists it with its command" "$(gb presets)" "@nightly"
check "print @preset" "$P clean && $P detekt" "$(gb print @nightly)"
tui "pick ● nightly" "pick Run it" > /dev/null
check "a preset runs from the menu" \
  "$(printf -- '--continue --parallel --console=rich clean\n--continue --parallel --console=rich detekt')" "$(gradle_runs)"
tui "key del ● nightly" "pick No, keep" "esc" > /dev/null
check "deleting asks first (No keeps it)" "yes" "$([ -f "$preset" ] && echo yes || echo no)"
tui "key del ● nightly" "pick Yes, delete" "esc" > /dev/null
check "deleting with Yes removes it" "no" "$([ -f "$preset" ] && echo yes || echo no)"

echo "== looks"
tui "esc" > /dev/null
contains "one plain arrow for the cursor" "$(cat "$FAKE_FZF_LOG")" "--pointer=▶"
contains "and + for ticked rows" "$(cat "$FAKE_FZF_LOG")" "--marker=+"

echo "== other build tools (runner:)"
MREPO=$T/make-repo; export MAKE_LOG=$T/make.log
mkdir -p "$MREPO/lib/a" && cd "$MREPO"
git init -q -b main
printf 'lint:\n\ttrue\n' > Makefile
cat > .tb <<'EOF'
runner: make -k
# step | label | task | where | auto
4 | Unit tests  | test   | module | auto
3 | Lint        | lint   | root   | auto
5 | Build app   | build  | :app
1 | Clean       | clean  | root
2 | Format      | format | root
EOF
git add -A && git commit -qm init && git checkout -qb work
echo x > lib/a/file.txt
cd - > /dev/null
printf '#!/usr/bin/env bash\necho "$*" >> "$MAKE_LOG"\n' > "$T/bin/make"; chmod +x "$T/bin/make"
mgb() { (cd "$MREPO" && "$TB" "$@"); }
check "list shows the runner first" "runner: make -k" "$(mgb list | sed -n 1p)"
contains "without gradlew module commands run on the whole project" "$(mgb list)" "4     test                       root     auto  Unit tests"
contains "and fixed-module ones too" "$(mgb list)" "5     build                      root     -     Build app"
check "print uses the runner" "make -k lint" "$(mgb print lint)"
check "module commands need no modules" "make -k test" "$(mgb print test)"
check ":name commands get no module prefix" "make -k build" "$(mgb print build)"
check "steps 1-2 still run first, on their own" "make -k clean format && make -k lint test build" "$(mgb print build test lint format clean)"
check "auto adds the auto commands" "make -k lint test" "$(mgb print auto)"
check "no modules without gradlew" "" "$(mgb modules)"
check "no changed modules without gradlew" "" "$(mgb changed)"
contains "refresh says there is nothing to read" "$(mgb refresh)" "No ./gradlew here"
contains "help shows the runner" "$(mgb help)" "Runner: make -k"
: > "$MAKE_LOG"; mgb run lint test > /dev/null
check "run calls the runner" "-k lint test" "$(cat "$MAKE_LOG")"
check "history keeps it" "make -k lint test" "$(mgb history)"
: > "$MAKE_LOG"
printf '%s\n' "pick ★ Auto" "pick ▶ Run" "pick Confirm" > "$FAKE_FZF_SCRIPT"; : > "$FAKE_FZF_LOG"
(cd "$MREPO" && TB_INTERACTIVE=1 "$TB" < /dev/null) > /dev/null
check "menu: Auto, then run, with the runner" "-k lint test" "$(cat "$MAKE_LOG")"
contains "menu header starts with the runner" "$(cat "$FAKE_FZF_LOG")" "make -k"
lacks "the menu never mentions gradlew" "$(cat "$FAKE_FZF_LOG")" "gradlew"
export GB_STATE=$T/state GB_CHANGED=""; : > "$GB_STATE"
contains "module commands tick in place like root ones" "$(FZF_SELECT_COUNT=0 mgb __enter cmd test root)" "reload-sync("
unset GB_STATE GB_CHANGED
mkdir -p "$T/empty" && (cd "$T/empty" && git init -q)
out=$( (cd "$T/empty" && "$TB" list) 2>&1); rc=$?
check "no gradlew and no runner: exit 1" "1" "$rc"
contains "and says how to fix it" "$out" "add a runner: line to .tb"
contains "help still works there" "$( (cd "$T/empty" && "$TB" -h) )" "a task board for Gradle"

echo "== command list: .tb, ~/.config/tb/commands, built-in"
global=$HOME/.config/tb/commands
(cd "$REPO" && mv .tb .tb.keep)
contains "no list anywhere: the built-in one" "$(gb list)" "lintDebug"
contains "and help says so" "$(gb help)" "Commands from the built-in list"
mkdir -p "$(dirname "$global")"
printf '3 | Detekt | detekt | root | auto\n4 | Tests | testDebugUnitTest | module | auto\n' > "$global"
check "the global list is used when there is no .tb" "detekt" "$(gb list | awk 'NR==3{print $2}')"
contains "and help names it" "$(gb help)" "Commands from $global"
check "global list without runner: the gradle default" "$P detekt" "$(gb print detekt)"
printf 'runner: ./gradlew --offline\n' >> "$global"
check "runner: in the global list" "./gradlew --offline detekt :lib:a:testDebugUnitTest" "$(gb print auto)"
check "list shows the global runner" "runner: ./gradlew --offline" "$(gb list | sed -n 1p)"
(cd "$REPO" && mv .tb.keep .tb)
check ".tb wins over the global list" "runner: $P" "$(gb list | sed -n 1p)"
(cd "$MREPO" && mv .tb .tb.keep)
printf 'runner: just\n3 | Lint | lint | root | auto\n4 | Test | test | module\n' > "$global"
check "global runner without gradlew" "just lint test" "$(mgb print test lint)"
(cd "$MREPO" && mv .tb.keep .tb)
printf 'runner: one\nrunner: two  \n3 | Lint | lint | root\n' > "$global"
(cd "$MREPO" && mv .tb .tb.keep)
check "the last runner line wins, trailing spaces trimmed" "two lint" "$(mgb print lint)"
(cd "$MREPO" && mv .tb.keep .tb)
rm -f "$global"

echo "== example/.tb"
cp "$REPO/.tb" "$T/tb.keep"; cp "$here/../example/.tb" "$REPO/.tb"
out=$(gb list)
check "example: default runner" "runner: $P" "$(sed -n 1p <<< "$out")"
want=$(grep -vE '^[[:space:]]*(#|$)' "$here/../example/.tb" | awk -F'|' '{ gsub(/[[:space:]]/, "", $3); print $3 }')
check "example: every row is listed" "$(wc -l <<< "$want" | tr -d ' ')" "$(sed 1,2d <<< "$out" | wc -l | tr -d ' ')"
check "example: in the same order, with the same tasks" "$want" "$(sed 1,2d <<< "$out" | awk '{print $2}')"
check "example: auto checks on changed modules" "$P ktlintCheck detekt :lib:a:lintDebug :lib:a:testDebugUnitTest" "$(gb print auto)"
cp "$T/tb.keep" "$REPO/.tb"

echo "== install.sh"
# Stubs only: nothing is downloaded or installed. fzf reports $FAKE_FZF_VERSION; git clone and
# curl -o leave a fake file behind and log what they were asked.
I=$T/install; mkdir -p "$I/stubs" "$I/brewbin" "$I/home" "$I/elsewhere"
export INSTALL_LOG=$I/log
cat > "$I/stubs/fzf" <<'EOF'
#!/bin/sh
echo "${FAKE_FZF_VERSION:-0.60.0} (stub)"
EOF
cat > "$I/stubs/git" <<'EOF'
#!/bin/sh
echo "git $*" >> "$INSTALL_LOG"
if [ "$1" = clone ]; then
  for a; do dest=$a; done
  mkdir -p "$dest/bin"
  printf '#!/bin/sh
printf "#!/bin/sh\necho 0.70.0\n" > "$(dirname "$0")/bin/fzf"; chmod +x "$(dirname "$0")/bin/fzf"
' > "$dest/install"
  chmod +x "$dest/install"
fi
EOF
cat > "$I/stubs/curl" <<'EOF'
#!/bin/sh
echo "curl $*" >> "$INSTALL_LOG"
while [ $# -gt 0 ]; do [ "$1" = -o ] && { echo '# downloaded tb' > "$2"; }; shift; done
EOF
printf '#!/bin/sh
echo "brew $*" >> "$INSTALL_LOG"
' > "$I/brewbin/brew"
chmod +x "$I"/stubs/* "$I/brewbin/brew"
install_sh() { # bin-dir extra-path, then env; runs install.sh with only the stubs and the system dirs on PATH
  local bin=$1 extra=$2; shift 2
  : > "$INSTALL_LOG"; rm -rf "$I/home/.fzf"
  env -i HOME="$I/home" PATH="$I/stubs${extra:+:$extra}:/usr/bin:/bin" INSTALL_LOG="$INSTALL_LOG" TB_BIN="$bin" "$@" \
    "$BASH" "$here/../install.sh" 2>&1
}
out=$(install_sh "$I/bin1" ""); rc=$?
check "install: exits 0" "0" "$rc"
check "install: copies tb" "yes" "$(cmp -s "$here/../tb" "$I/bin1/tb" && [ -x "$I/bin1/tb" ] && echo yes || echo no)"
contains "install: a new enough fzf is kept" "$out" "✔ fzf 0.60.0"
check "install: nothing fetched" "" "$(cat "$INSTALL_LOG")"
contains "install: says where tb went" "$out" "tb installed in $I/bin1"
contains "install: asks to add the bin dir to PATH" "$out" "export PATH=\"$I/bin1:"
out=$(install_sh "$I/bin2" "" FAKE_FZF_VERSION=0.45.0); rc=$?
check "install, old fzf, no brew: exits 0" "0" "$rc"
contains "install, old fzf, no brew: clones fzf" "$(cat "$INSTALL_LOG")" "git clone -q --depth 1 https://github.com/junegunn/fzf.git $I/home/.fzf"
check "install, old fzf, no brew: links the new fzf into the bin dir" "$I/home/.fzf/bin/fzf" "$(readlink "$I/bin2/fzf")"
lacks "install, old fzf, no brew: and no old-fzf warning after" "$out" "older fzf comes first"
out=$(install_sh "$I/bin3" "$I/brewbin" FAKE_FZF_VERSION=0.45.0); rc=$?
check "install, old fzf, brew: exits 0" "0" "$rc"
check "install, old fzf, brew: uses brew" "brew install fzf" "$(cat "$INSTALL_LOG")"
contains "install, old fzf, brew: warns the old fzf still comes first" "$out" "older fzf comes first"
out=$(cd "$I/elsewhere" && : > "$INSTALL_LOG" && env -i HOME="$I/home" PATH="$I/stubs:/usr/bin:/bin" INSTALL_LOG="$INSTALL_LOG" \
  TB_BIN="$I/bin4" "$BASH" < "$here/../install.sh" 2>&1); rc=$?
check "install piped from curl: exits 0" "0" "$rc"
contains "install piped from curl: downloads tb" "$(cat "$INSTALL_LOG")" "raw.githubusercontent.com/cicerohellmann/taskboard/main/tb -o $I/bin4/tb"
check "install piped from curl: and makes it executable" "yes" "$([ -x "$I/bin4/tb" ] && echo yes || echo no)"

echo "== fzf version"
mkdir -p "$T/oldbin"; printf '#!/bin/sh\necho "0.45.0 (old)"\n' > "$T/oldbin/fzf"; chmod +x "$T/oldbin/fzf"
out=$(cd "$REPO" && PATH="$T/oldbin:$PATH" TB_INTERACTIVE=1 "$TB" < /dev/null 2>&1); rc=$?
check "fzf older than 0.46 is refused" "1" "$rc"
contains "and says which version it found" "$out" "this is 0.45.0"
check "print works without fzf at all" "$P detekt" "$(PATH="$T/oldbin:$PATH" gb print detekt)"

echo
echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
