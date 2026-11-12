# Changelog

What changed in each version of tb. The words are in [docs/WORDS.md](docs/WORDS.md).

## 0.4.0 (2026-11-12)

### New

- `tb init` asks Gradle for every task of every module and opens a list to tick. ENTER writes the ticked tasks to `.tb`. See [tb init](MANUAL.md#tb-init).
  - Tasks you ran before from your shell history come first, with `★` and the number of runs. Then the common Android tasks your project has. Both are ticked.
  - Type to search every other task.
  - TAB ticks a task. CTRL-T turns `auto` on or off.
  - Each row shows the label, the task, where it runs, and its description from Gradle.
  - With a `.tb` already, its tasks are ticked. ENTER saves the old one as `.tb.bak` and keeps its lines that are not in the list.
- `tb init --defaults` writes the built-in task list, as `tb init` did before. `tb init` without a terminal does the same.
- While tb waits for Gradle on a terminal, it shows `Reading tasks from Gradle… 4s`. CTRL-C stops it.
- tb keeps the tasks of each module in `~/.cache/tb/`. It reads them again when a build file changes, or on `tb refresh`.
- `tb refresh` prints the number of modules and tasks.
- [README.md](README.md#update) explains how to update tb.
- `tests/tty.sh` tests tb in a real terminal with the real fzf. GitHub Actions runs it.

### Fixed

- A module that does not have the task made the whole build fail with `Cannot locate tasks that match ':module:task'`. Fixed: the modules screen lists only the modules that have the task. Auto, `tb print` and `tb run` leave the others out, and say `Skipped, no such task there: ...`.
- The modules screen listed a folder that has no build file. Fixed: it has no tasks, so it is not listed.
- The first run in a project showed no progress until Gradle was done. Fixed: on a terminal, tb shows the seconds.

### Known issues

- If Gradle can't list the tasks, tb works as in 0.3.0: a module that does not have the task makes the whole build fail.
- `◆ ALL MODULES` and `task=ALL` write the task with no module in front. Gradle runs it only in the modules that have it.
- A whole-project task or a fixed-module task ignores `=modules`. Example: `installDebug=:x` runs `:app:installDebug`, with no error.
- `tb init` asks Gradle every time, even when the tasks are cached. It needs the descriptions, and they are not cached.
- In `tb init`, the other tasks have no description.
- `tb init` does not keep the comment lines of the old `.tb`. They are in `.tb.bak`.

## 0.3.0 (2026-11-12)

### New

- The modules screen has a `◆ CHANGED AND DEPENDENT MODULES (N)` row. It ticks the affected modules. N is how many.
- The modules screen marks changed modules with `★` and modules that depend on a changed one with `☆`.
- CTRL-A ticks every row shown, on the modules screen and the test classes screen. Type to filter first to tick only some rows.
- `tb help` lists CTRL-A. The `by hand` line no longer says "go deep".
- The docs are split: [README.md](README.md) to install and start, [MANUAL.md](MANUAL.md) for every detail, [docs/AI.md](docs/AI.md) for AI agents, [docs/WORDS.md](docs/WORDS.md) for the words, [CONTRIBUTING.md](CONTRIBUTING.md) to change tb, and this changelog.
- `AGENTS.md`, `CLAUDE.md` and `.github/copilot-instructions.md` point AI agents to [docs/AI.md](docs/AI.md).

### Fixed

- Reopening a task's modules screen or test classes screen showed nothing ticked, so ticking again replaced the earlier modules. Fixed: the earlier modules and test classes are ticked.
- Back in the main menu, the cursor went to the top row. Fixed: it stays on the row you ticked.
- Unit tests and a Paparazzi task on the same module ran only one picked test class. Both run the module's unit test task, and their `--tests` replaced each other. Fixed: they share the picked test classes, or run all tests if one of them has all.
- Auto after picking test classes by hand left the modules Auto added out of the test task. Fixed: the added modules run all their tests.
- `tb print lintDebug=:a lintDebug=:b` kept only the last SPEC. Fixed: the same module task twice runs on both sets of modules. Same for `tb run`.
- `tb history` did not move a repeated command to the end. Fixed: each command shows once, at its newest run, newest last.
- The run screen cut long commands with `··`. Fixed: a long command is shown on several lines. Same on the preset screen.
- A ticked task's row in the main menu showed modules and a test class count that would not run. Fixed: it lists only the modules the task runs on, and counts only the test classes it gets.

### Known issues

- A module that does not have the task makes the whole build fail with `Cannot locate tasks that match ':module:task'`. Example: a Paparazzi task on a module without Paparazzi, picked by hand or added by Auto.
- The modules screen can list a folder that has no build file. A task on it fails the same way.
- `◆ ALL MODULES` and `task=ALL` are not affected. tb writes the task with no module in front, and Gradle runs it only in the modules that have it.
- A whole-project task or a fixed-module task ignores `=modules`. Example: `installDebug=:x` runs `:app:installDebug`, with no error.
- The first run in a project shows `Reading the module list from Gradle (only after settings change)...` and no progress until Gradle is done.

## 0.2.0 (2026-11-11)

### New

- Auto also runs on the modules that depend on a changed module. tb reads the dependencies from each module's build file.
- `tb affected` lists the affected modules.
- SPEC `task=affected` runs a module task on the affected modules.
- [HOW-WE-BUILT-IT.md](HOW-WE-BUILT-IT.md): what the author asked for, what was built, similar tools and references.
- The README explains every menu row as text. The screenshots are gone.

## 0.1.0 (2026-11-11)

First release.

- A menu for Gradle tasks, made with fzf. Tick tasks, pick modules and test classes. tb runs them in one command.
- `★ Auto` ticks the `auto` tasks on the changed modules.
- Step order: clean, formatting, checks, tests, builds, reports. Steps 1 and 2 run as their own call first.
- Presets: save the ticked tasks and run them again.
- The task list is in a `.tb` file. `tb init` writes one to start from.
- Commands for scripts: `tb print`, `tb run`, `tb list`, `tb modules`, `tb changed`, `tb presets`, `tb history`, `tb last`, `tb hist`, `tb refresh`, `tb agents`, `tb help`.
- A `runner:` line in `.tb` replaces `./gradlew` with another build tool.
- Install with Homebrew (`brew install cicerohellmann/tap/tb`) or with `install.sh`.
