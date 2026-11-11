<h1><img src="docs/banner.png" alt="Task Board (tb)" width="300"></h1>

[![tests](https://github.com/cicerohellmann/taskboard/actions/workflows/test.yml/badge.svg)](https://github.com/cicerohellmann/taskboard/actions/workflows/test.yml)

![tb: ticking unit tests on the modified modules, clean and the auto tasks, then running them](demo/demo.gif)

Task Board (`tb`) runs Gradle tasks.
You tick the tasks. You pick the modules. tb runs them in one build, in the right order.

## Why

Like you, I've always had trouble testing exactly what I want to test.

- Running every task takes too long.
- Running one task by hand means typing long task names.

tb does two things:

1. **Auto.** tb detects the modified modules and runs your standard tools there.
2. **By hand.** You go deep into your tasks and your modules, and you define how every task runs.

## Auto

- Your standard tools are the tasks marked `auto` in `.tb`. Example: lint, detekt, ktlint, unit tests.
- A modified module is a module with changes on your branch, compared with `main`. Uncommitted and new files count.
- Auto runs the `auto` tasks on the modified modules.

Run it:

```sh
tb run auto
```

Or pick ★ Auto in the menu.

## By hand

- Pick a task.
- Pick its modules.
- Pick its test classes.
- Tick more tasks.
- Run.

tb runs the tasks in this order, always:

| Step | Tasks |
|---|---|
| 1 | clean |
| 2 | tasks that change files (formatting) |
| 3 | checks |
| 4 | tests |
| 5 | builds |
| 6 | reports |

Steps 1 and 2 run as their own build first.

## The menu, row by row

### Main menu

| Row | What it does |
|---|---|
| `▶ Run` | Shows the command. Confirm runs it. |
| `💾 Save as preset` | Saves the ticked tasks as a preset. |
| `★ Auto: checks on changed modules (:garden, :notes:editor)` | Ticks the `auto` tasks on the modified modules. |
| `Instrumented tests (needs a device)` | A task. ENTER opens it. You pick its modules. |
| `✓ Unit tests → :garden, :notes:editor · 1 test class` | A ticked task, with its modules and test classes. |
| `✓ Clean → whole project` | A ticked whole-project task. Whole-project tasks tick with ENTER. No module screen. |
| `● before-push · Unit tests, Clean` | A preset. ENTER shows its command, then runs it or deletes it. DEL deletes it. |

Top of the main menu:

| Line | What it shows |
|---|---|
| `★ Added the auto checks; module ones on :garden, :notes:editor` | What the last action did. |
| `./gradlew --continue --parallel --console=rich :garden:lintDebug :garden:testDebugUnitTest` | The command that will run. |

### Modules screen

| Row | What it does |
|---|---|
| `◆ ALL MODULES` | Runs the task on every module. |
| `★ :garden` | A modified module. Modified modules are at the top. TAB ticks it. |

### Test classes screen

| Row | What it does |
|---|---|
| `◆ ALL tests in these modules` | Runs every test class in the picked modules. |
| `★ MarkdownParserTest (:notes:editor)` | A test class in a modified file. TAB ticks it. |
| `📸 EditorScreenshotTest (:notes:editor)` | A screenshot test class (Paparazzi). |

### Run screen

| Row | What it does |
|---|---|
| `./gradlew ... clean && ./gradlew ... :notes:editor:testDebugUnitTest` | The command. |
| `✖ Cancel, back` | Goes back to the main menu. |
| `✔ Confirm, run it` | Runs the command. |

### Save screen

| Row | What it does |
|---|---|
| `name > before-push` | Type the preset name. ENTER saves. |

## Keys

| Key | What it does |
|---|---|
| ENTER | Opens a task. Ticks a whole-project task. |
| TAB | Ticks several rows. |
| DEL / CTRL-D | Deletes a preset. |
| ESC | Back. Quit. |

## Install

macOS or Linux, with Homebrew:

```sh
brew install cicerohellmann/tap/tb
```

Without Homebrew:

```sh
curl -fsSL https://raw.githubusercontent.com/cicerohellmann/taskboard/main/install.sh | bash
```

The installer puts `tb` in `~/.local/bin`. It installs fzf 0.46 or newer if fzf is missing or older.

tb needs `bash`, `git` and [fzf](https://github.com/junegunn/fzf) 0.46 or newer.

## Set it up

1. Run `tb init` in the project root. It writes `.tb`.
2. Edit `.tb`. List your project's tasks.
3. Mark your standard tools `auto`.
4. Commit `.tb`. Your team and their AI agents use the same list.

[`example/.tb`](example/.tb) is a full example.

## Set it up with an AI agent

Paste this into Claude Code, Codex or another agent, inside your project:

```text
Set up tb (https://github.com/cicerohellmann/taskboard) for this project.

1. Find out which build commands this project really uses:
   - my shell history (~/.zsh_history, ~/.bash_history): ./gradlew lines run in this project
   - CI workflow files (.github/workflows, .gitlab-ci.yml, bitrise.yml and similar)
   - build scripts and the plugins they apply (Detekt, Ktlint, Spotless, Paparazzi, Kover...)
   - README and CONTRIBUTING
2. Run `tb init`, then rewrite .tb with those commands, following the format and comments in it.
   Mark the standard checks someone should run before pushing (lint, static analysis, formatting
   checks, unit tests) as `auto`. Don't add tasks the project doesn't have.
3. Check it with `tb list` and `tb print auto`.
4. Add the output of `tb agents` to AGENTS.md or CLAUDE.md.
```

## The .tb file

One task per line:

```
# step | label                    | task              | where  | auto
3      | Android lint             | lintDebug         | module | auto
4      | Unit tests               | testDebugUnitTest | module | auto
5      | Build debug APK          | assembleDebug     | :app
1      | Clean                    | clean             | root
3      | Detekt (static analysis) | detekt            | root   | auto
2      | Ktlint: fix formatting   | ktlintFormat      | root
```

| Column | What it means |
|---|---|
| step | The run order, 1 to 6. See [By hand](#by-hand). |
| label | The name in the menu. |
| task | The Gradle task. |
| where | `module`: you pick modules. `root`: the whole project. `:name`: always that module. |
| auto | `auto`: Auto runs this task. |

Where tb looks for the task list:

1. `.tb` in the project root.
2. `~/.config/tb/commands`.
3. The built-in Android list.

Other files:

| File | What it holds |
|---|---|
| `~/.config/tb/presets/` | Presets. |
| `~/.tb_history` | History. |
| `~/.cache/tb/` | The module list. tb reads it again when the settings files change. `tb refresh` reads it again now. |

## Not only Gradle

tb is designed for Gradle. You can use it with anything else.

Add a `runner:` line to `.tb`:

```
runner: make -k
```

- tb puts the tasks after the runner, in run order.
- Without `./gradlew`, there are no modules. Every task runs on the whole project.
- Auto runs every `auto` task.

The default runner is `./gradlew --continue --parallel --console=rich`.

## For scripts and AI agents

These commands never open the menu:

| Command | What it does |
|---|---|
| `tb run auto` | Runs the `auto` tasks on the modified modules. |
| `tb print auto` | Prints the same command. Does not run it. |
| `tb run SPEC...` | Runs these tasks. |
| `tb print SPEC...` | Prints the command for these tasks. |
| `tb list` | Lists the tasks: step, task, where, auto, label. |
| `tb modules` | Lists every module. |
| `tb changed` | Lists the modified modules. |
| `tb presets` | Lists the presets. |
| `tb history` | Lists the commands run before. |
| `tb last` | Runs the last command again. |
| `tb hist` | Picks a command run before and runs it again. |
| `tb agents` | Prints a note for AGENTS.md or CLAUDE.md. |
| `tb help` | Prints the help. Same as `tb -h`. |

SPEC is one of:

| SPEC | What it means |
|---|---|
| `task` | A whole-project or fixed-module task. Example: `detekt`. |
| `task=:a,:b` | A module task on modules `:a` and `:b`. |
| `task=ALL` | A module task on every module. |
| `task=changed` | A module task on the modified modules. |
| `auto` | The `auto` tasks on the modified modules. |
| `@name` | A preset. |

Example:

```sh
tb print clean detekt testDebugUnitTest=changed
# ./gradlew ... clean && ./gradlew ... detekt :notes:editor:testDebugUnitTest
```

A task that is not in the list goes to the build as it is.
A mistake (unknown module, no modules, unknown preset) exits with 1 and says what is wrong.

## Try it

```sh
demo/make-project.sh /tmp/tb-demo && cd /tmp/tb-demo && tb
```

This makes the project from the GIF. Its `./gradlew` only prints the task names.

## Tests

```sh
tests/run.sh
```

- The tests use a fake Gradle project and a fake fzf.
- They need no Gradle, no Android SDK and no terminal.
- GitHub Actions runs them on Linux and macOS on every push.

## License

[The Unlicense](LICENSE). Copy it, change it, sell it, do whatever you want with it.
