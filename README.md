# gboard

A command board for Gradle projects, for developers (and AI agents) with too many commands under their belt.

Tick the commands you want, pick the modules, press Run. gboard builds one `./gradlew` line in the right order,
so you stop retyping long task paths or looking up which task does what.

```
gboard >
  ▶ Run
  💾 Save as preset
  ★ Auto: checks on changed modules (:notes:editor, :garden)
✓ Unit tests  → :notes:editor, :garden
  Android lint
✓ Clean  → whole project
  Build debug APK
  ...

./gradlew --continue --parallel --console=rich clean
then ./gradlew --continue --parallel --console=rich :notes:editor:testDebugUnitTest :garden:testDebugUnitTest
```

## What it does

- **Commands, then modules, then test classes.** Pick a command, tick its modules (modules changed on your
  branch are starred and on top), optionally narrow it down to some test classes, and you're back on the list.
- **Whole-project commands are just a tick.** Clean, Detekt, Ktlint and similar toggle in place.
- **Always the right order.** However you tick things, clean runs first, then formatting, checks, tests,
  builds, reports. Things that change files run as their own build first, so nothing checks half-formatted code.
- **★ Auto** adds the usual checks on the modules changed on your branch.
- **Presets.** Save a selection under a name and it sits at the top of the list next time.
- **History.** `gboard last` reruns the last command, `gboard hist` picks one from before.
- **For AI agents and scripts.** `gboard print ...` returns the exact command without opening anything
  (see [below](#for-ai-agents-and-scripts)).

## Install

macOS or Linux, with `bash`, `git` and [fzf](https://github.com/junegunn/fzf) 0.46 or newer.

```sh
curl -fsSL https://raw.githubusercontent.com/cicerohellmann/gboard/main/install.sh | bash
```

This puts `gboard` in `~/.local/bin` and installs fzf if it's missing or too old (with Homebrew if you
have it, otherwise fzf's own release). Linux distro packages of fzf are often older than 0.46, which is why
it doesn't just use those. From a clone, run `./install.sh` instead.

Make sure `~/.local/bin` is on your `PATH`, then run `gboard` anywhere inside a project that has `./gradlew`.

## Set it up for your project

Out of the box gboard uses a standard Android list (lint, unit tests, instrumented tests, APK builds, clean).
To match your project:

```sh
gboard init     # writes .gboard in the project root
```

Edit `.gboard`. One command per line:

```
# step | label                    | gradle task       | where  | auto
3      | Android lint             | lintDebug         | module | auto
4      | Unit tests               | testDebugUnitTest | module | auto
5      | Build debug APK          | assembleDebug     | :app
1      | Clean                    | clean             | root
3      | Detekt (static analysis) | detekt            | root   | auto
2      | Ktlint: fix formatting   | ktlintFormat      | root
```

| Column | Meaning |
|---|---|
| step | Run order: 1 clean, 2 changes files, 3 checks, 4 tests, 5 build, 6 reports. Steps 1-2 run as their own build first. |
| label | What you see in the list. |
| gradle task | The task name. |
| where | `module`: you pick modules. `root`: whole project, just a tick. `:something`: always that module. |
| auto | `auto` means ★ Auto adds it. |

Commit `.gboard` so your team (and their agents) share the list, or add it to `.git/info/exclude` to keep it
to yourself. A list in `~/.config/gboard/commands` applies to every project without its own `.gboard`.

Modules come from `./gradlew projects`, cached until your settings files change. `gboard refresh` re-reads them.

## Keys

| Key | |
|---|---|
| ENTER | open a command, or tick a whole-project one |
| TAB | tick several |
| DEL / CTRL-D | delete a preset |
| ESC | back / quit |

## For AI agents and scripts

Everything below works without a terminal and never opens the picker. Run with no terminal attached,
plain `gboard` prints this help instead of waiting for input.

```sh
gboard list                                   # the commands: step, task, where, label
gboard modules                                # every Gradle module
gboard changed                                # modules changed on this branch
gboard print clean detekt testDebugUnitTest=changed
# ./gradlew ... clean && ./gradlew ... detekt :notes:editor:testDebugUnitTest
gboard run lintDebug=:garden assembleDebug   # same, and run it
```

What you can pass to `print` and `run`:

| | |
|---|---|
| `task` | a whole-project or fixed-module command, e.g. `detekt` |
| `task=:a,:b` | a per-module command on those modules (`=ALL` and `=changed` work too) |
| `auto` | the auto checks, on the modules changed on this branch |
| `@name` | a saved preset |

Anything not in the list is passed to Gradle as it is. Mistakes (unknown module, missing modules,
unknown preset) exit with 1 and say what's wrong.

`gboard agents` prints a short note to paste into your `AGENTS.md` or `CLAUDE.md`, so agents use your
project's task names instead of guessing them. `.gboard` explains itself too, so an agent can read it
without running anything.

## Files

| | |
|---|---|
| `.gboard` | the command list for a project |
| `~/.config/gboard/commands` | the command list for projects without one |
| `~/.config/gboard/presets/` | saved presets, per project |
| `~/.cache/gboard/` | cached module lists |
| `~/.gboard_history` | commands run |

## Tests

```sh
tests/run.sh
```

The tests build a small fake Gradle project and replace fzf with a script that plays back key presses
(`tests/fake-fzf`), so they need no Gradle, Android SDK or terminal. GitHub Actions runs them on Linux and
macOS on every push, and also runs the installer on a clean Linux machine.

## License

MIT
