#!/usr/bin/env bash
# tb tests in a real terminal: tmux runs tb with the real fzf in the demo project (demo/make-project.sh),
# sends key presses and reads the screen. Needs tmux and fzf 0.46+.
#   tests/tty.sh
#   FZF=/path/to/fzf tests/tty.sh     test another fzf
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
top=$(cd "$here/.." && pwd)
command -v tmux > /dev/null || { echo "tests/tty.sh needs tmux"; exit 1; }
fzf_bin=${FZF:-$(command -v fzf || true)}
[ -x "$fzf_bin" ] || { echo "tests/tty.sh needs fzf"; exit 1; }
echo "fzf $("$fzf_bin" --version | cut -d' ' -f1), tmux $(tmux -V | cut -d' ' -f2)"

T=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/tb-tty.XXXXXX")" && pwd -P)
sock=tb-tty-$$
trap 'tmux -L "$sock" kill-server 2>/dev/null; rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home"
ln -s "$fzf_bin" "$T/bin/fzf"
ln -s "$top/tb" "$T/bin/tb"
P=$T/p
"$top/demo/make-project.sh" "$P" > /dev/null
# Shell history: ktlintFormat twice, installDebug once, and a typo that is no task
printf ': 1700000000:0;./gradlew ktlintFormat\n: 1700000001:0;./gradlew ktlintFormat :app:installDebug\n: 1700000002:0;./gradlew detek\n' \
  > "$T/home/.zsh_history"

passed=0 failed=0
ok() { passed=$((passed + 1)); echo "ok    $1"; }
bad() { failed=$((failed + 1)); echo "FAIL  $1"; shift; printf '      %s\n' "$@"; }
check() { # name expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected: $2" "actual:   $3"; fi
}

X() { tmux -L "$sock" "$@"; }
X -u -f /dev/null new-session -d -x 160 -y 40 -s t \
  "env -i HOME='$T/home' PATH='$T/bin:$PATH' TERM=xterm-256color LC_ALL=C.UTF-8 PS1='$ ' bash --norc --noprofile"
# The screen as text, without fzf's border
screen() { X capture-pane -p -t t | sed 's/[│╭╮╰╯─]//g; s/ *$//'; }
# One row of a list, by task name, with single spaces: "[x] auto Android lint lintDebug module"
row() { screen | grep -E "(^| )$1( |$)" | grep -E '\[[x ]\]' | head -1 | sed 's/^ *▶//' | tr -s ' ' | sed 's/^ //'; }
# Waits until TEXT is on the screen (5s). Fails the test and prints the screen if it never comes.
see() { # name text
  local i
  for i in $(seq 50); do screen | grep -qF -- "$2" && { ok "$1"; return 0; }; sleep 0.1; done
  bad "$1" "not on the screen: $2" "screen:"; screen | grep -v '^$' | sed 's/^/      | /'; return 1
}
# Waits until a row looks like EXPECTED (5s)
see_row() { # name task expected
  local i
  for i in $(seq 50); do [ "$(row "$2")" = "$3" ] && { ok "$1"; return 0; }; sleep 0.1; done
  check "$1" "$3" "$(row "$2")"
}
keys() { X send-keys -t t "$@"; sleep 0.3; }
type_cmd() { X send-keys -t t "clear; $*" Enter; sleep 0.3; }
ticked_lines() { grep -v '^#' "$P/.tb" | tr -s ' '; }
type_cmd "cd '$P'"

echo "== tb init: loading"
type_cmd "DEMO_SLEEP=3 tb init"
see "shows that it is reading the tasks" "Reading tasks from Gradle… 1s"
see "and counts the seconds" "Reading tasks from Gradle… 2s"

echo "== tb init: the list, no .tb yet"
for i in $(seq 60); do screen | grep -qF 'tasks >' && break; sleep 0.1; done
see "the list opens" "tasks >"
see "the header names the keys" "TAB tick · CTRL-T auto on/off · type to search all 13 tasks · ENTER write .tb · ESC quit"
see_row "shell history first, with the count" ktlintFormat "[x] ★2 Ktlint: fix formatting ktlintFormat root Fixes Kotlin code style"
see_row "a fixed-module task" installDebug "[x] ★1 Install debug APK on device installDebug :app Installs the Debug build"
see_row "checks are auto" lintDebug "[x] auto Android lint lintDebug module"
see_row "tests are auto" testDebugUnitTest "[x] auto Unit tests testDebugUnitTest module Run unit tests for the debug build"
see_row "a task in one module runs there" verifyPaparazziDebug "[x] auto Screenshot tests: verify verifyPaparazziDebug :notes:editor"
see_row "a typo from the history is no row" detekt "[x] auto Detekt (static analysis) detekt root"
check "other tasks are hidden" "" "$(row help)"
keys "'help"
see_row "until you search" help "[ ] help help root"
keys Tab
see_row "TAB ticks" help "[x] help help root"
keys C-t
see_row "CTRL-T makes it auto" help "[x] auto help help root"
keys C-u
see_row "a ticked task stays in the list" help "[x] auto help help root"
keys Tab
see_row "TAB on the first row unticks it" ktlintFormat "[ ] ★2 Ktlint: fix formatting ktlintFormat root Fixes Kotlin code style"
keys Enter
see "ENTER writes .tb" "/.tb with 12 tasks."
check "in step order" "1 | Clean | clean | root
2 | Screenshot tests: record | recordPaparazziDebug | :notes:editor
3 | Android lint | lintDebug | module | auto
3 | Detekt (static analysis) | detekt | root | auto
3 | Ktlint: check formatting | ktlintCheck | root | auto
4 | Unit tests | testDebugUnitTest | module | auto
4 | Screenshot tests: verify | verifyPaparazziDebug | :notes:editor | auto
5 | Install debug APK on device | installDebug | :app
5 | Build debug APK | assembleDebug | :app
5 | Build release APK | assembleRelease | :app
5 | help | help | root | auto
6 | Coverage report | koverHtmlReport | root" "$(ticked_lines)"
check "the loading line is gone" "0" "$(screen | grep -c 'Reading tasks')"
check "no .tb.bak without an old .tb" "no" "$([ -e "$P/.tb.bak" ] && echo yes || echo no)"

echo "== tb init: ESC"
rm "$P/.tb"
type_cmd "tb init"
see "the list opens again" "tasks >"
keys Escape
see "ESC says so" "Nothing written."
check "and writes nothing" "no" "$([ -e "$P/.tb" ] && echo yes || echo no)"

echo "== tb init: with a .tb"
printf '# mine\n3 | My check | myCheck | root | auto\n4 | My tests | testDebugUnitTest | module | auto\n1 | Clean | clean | root\n' > "$P/.tb"
cp "$P/.tb" "$T/old.tb"
type_cmd "tb init"
see "the header says what happens to it" "Ticked: the tasks in your .tb. ENTER saves the old one as .tb.bak and keeps its other lines."
see_row "its tasks are ticked, with its label" testDebugUnitTest "[x] auto My tests testDebugUnitTest module Run unit tests for the debug build"
see_row "the others are not" ktlintFormat "[ ] ★2 Ktlint: fix formatting ktlintFormat root Fixes Kotlin code style"
keys Enter
see "ENTER says where the old one is" "The old one is in .tb.bak."
check ".tb.bak is the old .tb" "same" "$(cmp -s "$P/.tb.bak" "$T/old.tb" && echo same || echo different)"
check "lines not in the list are kept" "3 | My check | myCheck | root | auto
1 | Clean | clean | root
4 | My tests | testDebugUnitTest | module | auto" "$(ticked_lines)"

echo "== menu: only modules with the task"
type_cmd "tb"
see "the menu opens" "tb >"
keys "My tests"
keys Enter
see "the modules screen opens" "For: My tests"
see "it lists the modules with the task" ":notes:list"
check "and not the ones without it" "0" "$(screen | grep -cE ':settings|:notes$')"
keys ":notes:list"
keys Tab
keys Enter
see "the tests screen opens" "NoteListTest  (:notes:list)"
keys Enter
see "back in the menu, with the module" "My tests  → :notes:list"
keys "Run"
keys Enter
see "run asks first" "Confirm, run it"
keys Down
keys Enter
see "and runs it" "BUILD SUCCESSFUL"
see "the command" "▶ ./gradlew --continue --parallel --console=rich :notes:list:testDebugUnitTest"

echo
echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
