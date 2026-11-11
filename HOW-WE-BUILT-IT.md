# How we built it

tb was built by one person and an AI assistant (Claude), in a chat.
The person said what they wanted. The AI wrote the code. The person tried it and said what was wrong.

## The problem

Like you, I've always had trouble testing exactly what I want to test.

- Running every task takes too long.
- Running one task by hand means typing long task names.
- Gradle task names are hard to remember.

The first ask was a "DJ board": a board of commands to click through, not to type.

## What we thought about

Each line is a decision, and why.

| Decision | Why |
|---|---|
| fzf in the terminal, not an IDE plugin. | The terminal is where the commands run. fzf is small and fast. |
| One straight path: task, then modules, then test classes, then back. | A first version had a hub menu with an "Add to run list" step. Too many clicks. |
| Changed modules have a ★ and are at the top. | You almost always want the modules you changed. |
| The header has the same height all the time. | The menu jumped when something was ticked. That was annoying. |
| `▶ Run` and `💾 Save as preset` are always in the list. | Same reason. The rows below them never move. |
| One command for everything. | One `./gradlew` call is faster than many. `--continue` shows every failure, not only the first one. |
| A step column: clean, formatting, checks, tests, builds, reports. | The order of tasks matters. clean must run first. Formatting changes files, so it runs before the checks. |
| Steps 1 and 2 run as their own call. | With `--parallel`, Gradle can run the checks while clean or formatting still changes the files. A separate call finishes them first. |
| Presets, history, `tb last`. | The same set of tasks runs many times a day. |
| The task list lives in `.tb`, in the project. | Every project has different tasks. The team shares one file. |
| Auto is the first-class feature. | The most common case: run the standard checks on the modules I changed, before I push. |
| Auto also runs on the modules that depend on a changed module. | A change in `:core` can break `:app`. The affected-module plugins below do this; we added it after we found them. |
| Dependencies come from the build files, not from Gradle. | Running Gradle to get the graph is slow. Reading the build files takes a fraction of a second. |
| You can still go deep by hand. | Sometimes you want one task, on one module, on one test class. |
| `tb print` and `tb run` never open the menu. | AI agents and scripts can't use a menu. They get the same tasks and the same order. |
| `runner:` line. | tb is designed for Gradle. It can be used with anything else. |
| Tests with a fake Gradle project and a fake fzf. | "I want tests." The tests run with no Gradle, no Android SDK and no terminal. Two bugs got past the first tests; each one now has a test. |
| The Unlicense. | Copy it, do whatever you want with it. |

## What we changed on the way

- **The name.** gboard, then "command center" with the command `cc`. `cc` is the C compiler, so no. Then `coce`. Then **Task Board**, command `tb`.
- **The README.** The first version was too long and told a story. We rewrote it as a manual: short lines, the same words every time.
- **The screenshots.** First, full screenshots with an arrow on the row. Then, a picture of only that row. Then, no pictures: the row text in `code`.
- **Install.** First an install script. Then Homebrew: `brew install cicerohellmann/tap/tb`.
- **Affected modules.** First Auto ran only on the changed modules. After we looked at tools like this one, Auto also runs on the modules that depend on them.
- **Review.** Before publishing, separate AI agents read the README. One checked every claim against the code. One read it as a new user. One checked every file and every link.

## Other people's code

We did not look at other people's code to build tb.
The AI wrote it from what it already knew about fzf, Gradle, git and bash.

## Tools like this one

We looked for tools like tb after it was built. We did not want to make something that already exists.

Short answer: no tool we found does the whole thing. There are two groups:

- **Pickers.** They pick a task and run it. They don't pick modules, test classes, or changed modules.
- **Affected-module plugins.** They find changed modules and their dependents. They have no menu.

tb sits between the two.

### Pickers

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [lazygradle](https://pypi.org/project/lazygradle/) | A terminal UI to browse and run Gradle tasks. | Reading the output. Saved runs with flags and env vars. | Several tasks at once, modules per task, test classes, changed modules, step order, script mode. |
| [fzf-make](https://github.com/kyu08/fzf-make) | fzf picker for make, npm, pnpm, yarn, just and task. | Preview of the target. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [nur](https://pypi.org/project/nur/) | Finds tasks from many runners. Runs them from a menu or the shell. | Many runners, no config. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [task-runner-detector](https://docs.rs/crate/task-runner-detector/latest) | Finds runner configs in a folder. Picks one task and runs it. | JSON output. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [just `--choose`](https://github.com/casey/just) | Picks recipes from a justfile with fzf. | Nothing for Gradle. | Gradle. Modules, test classes, changed modules. |
| [gradle-fzf-completion](https://github.com/donat/gradle-fzf-completion), [fzf-gradle-tasks](https://github.com/tom-power/fzf-gradle-tasks) | zsh: TAB after `./gradlew` picks a task with fzf. | Works inside the normal shell prompt. | Everything after picking one task name. |
| [IntelliJ / Android Studio run configurations](https://www.jetbrains.com/help/idea/run-debug-gradle.html) | Saved Gradle runs in the IDE. | The debugger. The IDE. | Modules per task, test classes, changed modules, step order, terminal and script mode. |

### Affected-module plugins

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [AffectedModuleDetector](https://github.com/dropbox/AffectedModuleDetector) (Dropbox, archived) | Gradle plugin. Runs tests on changed modules and the modules that depend on them. | Follows the dependency graph. Runs inside Gradle, good for CI. | A menu. Test classes. Presets. |
| [affected-module-detector](https://github.com/danielriverolosa/affected-module-detector) (danielriverolosa) | Gradle plugin. Lists the affected tasks, dependents included. | Follows the dependency graph. A test-only change does not spread. A build-logic change hits every module. | A menu. Test classes. Presets. Works with other runners. |
| [dag-command](https://github.com/leandroBorgesFerreira/dag-command) | Gradle plugin. Writes the affected modules and the graph as JSON or CSV. | Follows the dependency graph. Machine-readable output. | Runs tasks. A menu. Test classes. |
| [change-tracker-plugin](https://github.com/ismaeldivita/change-tracker-plugin) (archived) | Gradle plugin. Adds `<task>ChangedModules` tasks. | Follows the dependency graph. | A menu. Test classes. Presets. |
| [Nx affected](https://nx.dev/docs/features/ci-features/affected) | Runs tasks whose inputs changed. Works with Gradle through a plugin. | Picks tasks by their inputs. | A menu. You don't have to adopt Nx. |

### Where tb is weaker

- tb reads the dependencies from the build files. The plugins ask Gradle. Dependencies added by plugins or convention plugins are found by the plugins, not by tb.
- A change in build logic (`buildSrc`, `build-logic`, the version catalog) does not make every module affected in tb. Some plugins do this.
- tb shows the output in the terminal and nothing more. lazygradle keeps it.
- tb needs a `.tb` file per project. nur and task-runner-detector need no config.

What we checked: each tool's own README or docs, a GitHub search for Gradle pickers and affected-module tools, and the Gradle docs. We did not check IntelliJ Marketplace plugins or Develocity.

## References

The official docs for each tool tb uses.

| Tool | What tb uses it for | Reference |
|---|---|---|
| fzf | The menu: `--multi`, `--expect`, `--header-first`, `--with-nth`, `--delimiter`, `--print-query`, `--bind`. `FZF_SELECT_COUNT` is why tb needs fzf 0.46. | [fzf](https://github.com/junegunn/fzf), [fzf docs](https://junegunn.github.io/fzf/) |
| Gradle | `--continue`, `--parallel`, `--console=rich`, `-q projects`. | [Gradle command-line interface](https://docs.gradle.org/current/userguide/command_line_interface.html) |
| Gradle | `--tests`: run the picked test classes. | [Gradle test filtering](https://docs.gradle.org/current/userguide/java_testing.html#test_filtering) |
| git | Changed files on the branch: `git merge-base`, `git diff --name-only`. | [git diff](https://git-scm.com/docs/git-diff), [git merge-base](https://git-scm.com/docs/git-merge-base) |
| git | New files not committed yet: `git ls-files --others`. | [git ls-files](https://git-scm.com/docs/git-ls-files) |
| bash | The script. | [Bash Reference Manual](https://www.gnu.org/software/bash/manual/) |
| Paparazzi | Screenshot test classes. | [Paparazzi](https://github.com/cashapp/paparazzi) |
| vhs | The GIF. | [vhs](https://github.com/charmbracelet/vhs) |
| Homebrew | The `brew install` formula. | [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook), [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap) |
| GitHub Actions | The tests on every push. | [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) |
| AGENTS.md | The note `tb agents` prints. | [agents.md](https://agents.md) |
| The Unlicense | The license. | [unlicense.org](https://unlicense.org) |
