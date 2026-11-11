# README screenshot of the script / AI side: vhs demo/screens-print.tape   (run from the repo root; uses ./tb,
# or the copy in $TB_DIR if set). Rebuilds the made-up project in /tmp/tb-screens. Writes docs/screens/print.png.
Output "/tmp/tb-screens-print.gif"
Set Shell "bash"
Set FontSize 15
Set Width 1800
Set Height 290
Set Padding 18
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

Hide
Type "export PATH=${TB_DIR:-$PWD}:$PATH HOME=/tmp/tb-screens-home FZF_DEFAULT_OPTS= PS1='\[\e[1;34m\]notes\[\e[0m\] (better-editor) $ ' && rm -rf $HOME && mkdir -p $HOME && demo/make-project.sh /tmp/tb-screens && cd /tmp/tb-screens && tb refresh >/dev/null 2>&1; clear" Enter
Sleep 1.5s
Show

Type "tb print auto" Enter
Sleep 1s
Type "tb list" Enter
Sleep 1.5s
Screenshot docs/screens/print.png
Sleep 1s
