# README screenshots of the menu: vhs demo/screens.tape   (run from the repo root; uses ./tb,
# or the copy in $TB_DIR if set)
# Rebuilds the made-up project in /tmp/tb-screens and a throwaway HOME each time, so it's re-runnable.
# Writes docs/screens/{menu,auto,modules,tests,tick,run,save,preset}.png. See also demo/screens-print.tape.
Output "/tmp/tb-screens.gif"
Set Shell "bash"
Set FontSize 15
Set Width 1800
Set Height 540
Set Padding 18
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

Hide
Type "export PATH=${TB_DIR:-$PWD}:$PATH HOME=/tmp/tb-screens-home FZF_DEFAULT_OPTS= PS1='\[\e[1;34m\]notes\[\e[0m\] (better-editor) $ ' && rm -rf $HOME && mkdir -p $HOME && demo/make-project.sh /tmp/tb-screens && cd /tmp/tb-screens && tb refresh >/dev/null 2>&1; clear" Enter
Sleep 1.5s
Show

# The menu, nothing ticked
Type "tb" Enter
Sleep 2s
Screenshot docs/screens/menu.png
Sleep 1s

# ★ Auto
Type "auto" Sleep 300ms Enter
Sleep 1.5s
Screenshot docs/screens/auto.png
Sleep 1s
Escape
Sleep 800ms
Hide
Type "clear" Enter
Sleep 300ms
Show

# Fresh menu: Unit tests on the two changed modules
Type "tb" Enter
Sleep 2s
Type "unit" Sleep 300ms Enter
Sleep 1.2s
Down Sleep 200ms Tab Sleep 200ms Tab
Sleep 500ms
Screenshot docs/screens/modules.png
Sleep 1s
Enter
Sleep 2s
Down Sleep 300ms Down Sleep 300ms Tab
Sleep 1s
Screenshot docs/screens/tests.png
Sleep 1s
Enter
Sleep 1.5s

# Clean (the last row) ticks in place
Down@120ms 12 Sleep 300ms Enter
Sleep 1.5s
Screenshot docs/screens/tick.png
Sleep 1s

# Run: the confirmation
Type "'Run" Sleep 300ms Enter
Sleep 2s Down
Sleep 1s
Screenshot docs/screens/run.png
Sleep 1s
Escape
Sleep 1.2s

# Save as preset
Type "'Save" Sleep 300ms Enter
Sleep 2s
Type "before-push"
Sleep 1s
Screenshot docs/screens/save.png
Sleep 1s
Enter
Sleep 1.5s
Screenshot docs/screens/preset.png
Sleep 1s
Escape
Sleep 500ms
