#!/usr/bin/env bash
# gboard tests. Builds a small fake Gradle project, swaps fzf for tests/fake-fzf (scripted key presses),
# then checks every command. No Gradle, Android SDK or terminal needed.
#   tests/run.sh
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GBOARD=${GBOARD:-$here/../gboard}
T=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/gboard-test.XXXXXX")" && pwd -P)   # real path: macOS temp dirs are symlinked
trap 'rm -rf "$T"' EXIT

export HOME=$T/home GRADLE_LOG=$T/gradle.log FAKE_FZF_SCRIPT=$T/fzf.script FAKE_FZF_LOG=$T/fzf.log
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
unset GB_STATE GB_CHANGED GBOARD_INTERACTIVE
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

gb() { (cd "$REPO" && "$GBOARD" "$@"); }
# Runs the menu with scripted key presses (see tests/fake-fzf), one per argument
tui() {
  printf '%s\n' "$@" > "$FAKE_FZF_SCRIPT"; : > "$FAKE_FZF_LOG"; : > "$GRADLE_LOG"
  (cd "$REPO" && GBOARD_INTERACTIVE=1 "$GBOARD" < /dev/null)
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
cat > .gboard <<'EOF'
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
contains "plain gboard prints help instead of waiting for input" "$out" "gboard print SPEC"
contains "help names the command list it uses" "$out" "$REPO/.gboard"

echo "== modules"
rm -rf "$HOME/.cache/gboard"; : > "$GRADLE_LOG"
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

echo "== run, history, last"
: > "$GRADLE_LOG"
gb run detekt assembleDebug > /dev/null
check "run calls gradle with the command" "--continue --parallel --console=rich detekt :app:assembleDebug" "$(gradle_runs)"
check "history keeps it" "$P detekt :app:assembleDebug" "$(gb history)"
: > "$GRADLE_LOG"; gb last > /dev/null
check "last runs it again" "--continue --parallel --console=rich detekt :app:assembleDebug" "$(gradle_runs)"

echo "== init and agents"
(cd "$REPO" && mv .gboard .gboard.keep)
out=$(gb init); contains "init writes .gboard" "$out" "Wrote $REPO/.gboard"
contains "the written list explains itself to agents" "$(cat "$REPO/.gboard")" "AI agents"
out=$(gb init 2>&1); rc=$?
check "init never overwrites" "1" "$rc"
(cd "$REPO" && mv .gboard.keep .gboard)
contains "agents prints a note for AGENTS.md" "$(gb agents)" "gboard print"

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

tui "pick Unit tests" "pickall :lib:a$" "esc" "pick Unit tests" "pick ✖ Remove" "pick ▶ Run" "esc" > /dev/null
check "removing a command takes it off the list" "" "$(gradle_runs)"

big=$T/big.gboard; cp "$REPO/.gboard" "$big.keep"; cp "$REPO/.gboard" "$big"
for i in $(seq 1 400); do echo "4 | Filler command number $i with a long label to fill the pipe buffer quickly ........ | filler$i | root" >> "$big"; done
cp "$big" "$REPO/.gboard"
out=$(tui "pick ★ Auto" "esc" 2>&1); rc=$?
check "a long menu does not crash after Auto (broken pipe)" "0" "$rc"
lacks "no broken pipe message" "$out" "Broken pipe"
cp "$big.keep" "$REPO/.gboard"

echo "== presets"
tui "pick Detekt" "pick Clean" "pick 💾 Save" "query nightly" "esc" > /dev/null
preset=$HOME/.config/gboard/presets/repo/nightly
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

echo "== fzf version"
mkdir -p "$T/oldbin"; printf '#!/bin/sh\necho "0.45.0 (old)"\n' > "$T/oldbin/fzf"; chmod +x "$T/oldbin/fzf"
out=$(cd "$REPO" && PATH="$T/oldbin:$PATH" GBOARD_INTERACTIVE=1 "$GBOARD" < /dev/null 2>&1); rc=$?
check "fzf older than 0.46 is refused" "1" "$rc"
contains "and says which version it found" "$out" "this is 0.45.0"
check "print works without fzf at all" "$P detekt" "$(PATH="$T/oldbin:$PATH" gb print detekt)"

echo
echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
