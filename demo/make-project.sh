#!/usr/bin/env bash
# Builds the made-up Android project the demo GIF is recorded in: ./make-project.sh DIR
set -euo pipefail
dir=$1
rm -rf "$dir"; mkdir -p "$dir"; cd "$dir"
git init -q -b main
for m in app notes/editor notes/list garden settings; do
  mkdir -p "$m/src/main/java" && echo "// $m" > "$m/src/main/java/Main.kt"
done
mkdir -p notes/editor/src/test/java garden/src/test/java notes/list/src/test/java
echo "class EditorViewModelTest" > notes/editor/src/test/java/EditorViewModelTest.kt
echo "class MarkdownParserTest" > notes/editor/src/test/java/MarkdownParserTest.kt
echo "// paparazzi" > notes/editor/src/test/java/EditorScreenshotTest.kt
echo "class WateringScheduleTest" > garden/src/test/java/WateringScheduleTest.kt
echo "class NoteListTest" > notes/list/src/test/java/NoteListTest.kt
printf 'include(":app", ":notes:editor", ":notes:list", ":garden", ":settings")\n' > settings.gradle.kts
cat > gradlew <<'G'
#!/usr/bin/env bash
# Pretend Gradle: lists the projects, and "runs" tasks quickly
if [ "$*" = "-q projects" ]; then
  printf "Root project 'notes'\n+--- Project ':app'\n+--- Project ':garden'\n+--- Project ':notes'\n|    +--- Project ':notes:editor'\n|    \\\\--- Project ':notes:list'\n\\\\--- Project ':settings'\n"
  exit 0
fi
case "$*" in *--init-script*) # tb reading the tasks (DEMO_SLEEP=3 makes it slow)
  sleep "${DEMO_SLEEP:-0}"
  for t in clean detekt ktlintCheck ktlintFormat koverHtmlReport help; do echo "TBTASK : $t"; done
  for t in testDebugUnitTest lintDebug assembleDebug assembleRelease installDebug clean; do echo "TBTASK :app $t"; done
  for t in testDebugUnitTest lintDebug verifyPaparazziDebug recordPaparazziDebug clean; do echo "TBTASK :notes:editor $t"; done
  for m in :notes:list :garden; do for t in testDebugUnitTest lintDebug clean; do echo "TBTASK $m $t"; done; done
  for t in lintDebug clean; do echo "TBTASK :settings $t"; done
  echo "TBTASK :notes clean"
  echo "TBINFO|ktlintFormat|formatting|Fixes Kotlin code style"
  echo "TBINFO|testDebugUnitTest|verification|Run unit tests for the debug build"
  echo "TBINFO|installDebug|Install|Installs the Debug build"
  exit 0 ;;
esac
for t in "$@"; do
  case "$t" in -*) continue ;; esac
  printf '\e[1m> Task %s\e[0m\n' "${t#:}" | sed 's/> Task \([^:]\)/> Task :\1/'
  sleep 0.25
done
printf '\n\e[1;32mBUILD SUCCESSFUL\e[0m in 6s\n'
G
chmod +x gradlew
git add -A && git -c user.name=demo -c user.email=demo@example.com commit -qm init
git checkout -q -b better-editor
echo "// changed" >> notes/editor/src/main/java/Main.kt
echo "class MarkdownParserTest // changed" > notes/editor/src/test/java/MarkdownParserTest.kt
echo "// changed" >> garden/src/main/java/Main.kt
