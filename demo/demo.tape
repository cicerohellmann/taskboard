# Records demo.gif: vhs demo/demo.tape (run ./make-project.sh /tmp/tb-demo first)
Output demo/demo.gif
Set Shell "bash"
Set FontSize 17
Set Width 1180
Set Height 680
Set Padding 18
Set Theme "Catppuccin Mocha"
Set TypingSpeed 70ms

Hide
Type "export HOME=/tmp/tb-demo-home FZF_DEFAULT_OPTS= PS1='\[\e[1;34m\]notes\[\e[0m\] (better-editor) $ ' && mkdir -p $HOME && cd /tmp/tb-demo && tb refresh >/dev/null 2>&1; clear" Enter
Sleep 500ms
Show

Type "tb" Sleep 400ms Enter
Sleep 1.8s

# A command with modules: pick it, tick modules, keep all tests
Type "unit" Sleep 700ms Enter
Sleep 1.5s
Down Sleep 400ms Tab Sleep 500ms Tab
Sleep 900ms Enter
Sleep 1.6s Enter
Sleep 1.8s

# A whole-project command just ticks in place
Type "clean" Sleep 600ms Enter
Sleep 1.6s Ctrl+U

# Auto adds the usual checks on the changed modules
Type "auto" Sleep 600ms Enter
Sleep 2.2s Ctrl+U

# Run it
Type "run" Sleep 600ms Enter
Sleep 1.5s Down Sleep 600ms Enter
Sleep 3.5s
