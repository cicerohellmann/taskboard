# Words

The style guide for the tb docs. Use these words, so we don't keep inventing new words for the same thing.

## The words

| Word | What it means |
|---|---|
| task | A Gradle task. Example: `testDebugUnitTest`. |
| task list | The tasks tb shows. It comes from the `.tb` file. |
| built-in task list | The task list tb uses when there is no `.tb` file. `tb init --defaults` writes it to `.tb`. |
| module task | A task you run on modules you pick. `where` is `module`. |
| whole-project task | A task that runs on the whole project. `where` is `root`. Example: `clean`. |
| fixed-module task | A task that always runs on one module. `where` is a module name. Example: `:app:assembleDebug`. |
| `auto` task | A task marked `auto` in the task list. |
| Auto | Runs the `auto` tasks on the affected modules. See [Auto](../MANUAL.md#auto). |
| By hand | You pick tasks, modules and test classes yourself. See [By hand](../MANUAL.md#by-hand). |
| changed module | A module with a changed file on your branch. See [Changed modules](../MANUAL.md#changed-modules). |
| affected module | A changed module, or a module that depends on a changed module. See [Affected modules](../MANUAL.md#affected-modules). |
| tick | Select a row. ENTER ticks one row. TAB ticks several rows. CTRL-A ticks every row shown. |
| preset | A saved set of ticked tasks, with their modules and test classes. |
| step | The run order of a task, 1 to 6. See [Step order](../MANUAL.md#step-order). |
| runner | The command tb puts the tasks after. Default: `./gradlew --continue --parallel --console=rich`. |
| SPEC | What `tb print` and `tb run` take: a task, `task=modules`, `auto` or `@preset`. See [Commands for scripts](../MANUAL.md#commands-for-scripts). |
| row | One line in a menu screen. |
| screen | One menu: main menu, modules screen, test classes screen, run screen, save screen, preset screen. |

## How to write

- Short and plain.
- Each line says what a thing does or what to type.
- Use the same word for the same thing every time. If a word is missing, add it to the table above first.
- No story. No reasons or problems you can't check in the code.
- A plain sentence or two per point. Not a wall of text, and not single words.
- Copy row text and help text exactly from the code, in `code`.

## Where things go

| Doc | What goes in it |
|---|---|
| [README.md](../README.md) | Install and basic use. Keep it short. |
| [MANUAL.md](../MANUAL.md) | Every detail. |
| [docs/AI.md](AI.md) | What an AI agent needs to use tb or to work on this repo. |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | How to change tb and run its tests. |
| [CHANGELOG.md](../CHANGELOG.md) | What changed in each version: New, Fixed, Known issues. |
