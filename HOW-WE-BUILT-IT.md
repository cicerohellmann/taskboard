# How we built it

## The problem

I've always had trouble with long custom commands that always keep changing, specially in big projects.

The first ask was a "DJ board": all the commands in one place. Click a command, open a list, select the modules. The commands are hard to remember.

## What we thought about

Each line is a decision, and why.

| Decision | Why |
|---|---|
| A menu in the terminal, with fzf. | The first ask was an app or a plugin. The AI built a terminal menu first, and it stayed. |
| Select modules from a list. | "when we want to run commands that could be module specific, like we could click, open a list and select which modules we want to run them". |
| Run more tasks at the same time, in one command. | "I want to run more commands simultaneously". |
| ▶ Run, then Cancel / Confirm. | "in case you accidentally press it twice". |
| Presets. | "a button … to save it as a preset". Run it or delete it, with a confirm before delete. |
| Open a task again: what was added is marked, you can add more. | "I would like to see some sort of marker showing the commands that are already added". |
| One straight path: task, then modules, then test classes, then back. | A later version had more screens. "There are too many clicks, too many options. I like the way it was in the beginning." |
| Ticking a row doesn't move the cursor. | "the window blinks and my arrow goes up. I want my arrow to continue on top of the selection I made." |
| Whole-project tasks are ticked on the main menu, with no module screen. | "These global comments, we can just select them here." |
| A step column. | "How do we guarantee order here?" clean must run first. Formatting changes files, so it runs before the checks. |
| Steps 1 and 2 run as their own call. | With `--parallel`, Gradle can run the checks while clean or formatting still changes the files. |
| Auto. | "auto-select modified modules". Later: "a first-class citizen auto runner that will detect the modified modules and run the commands there." |
| Auto also runs on the modules that depend on a changed module. | "check the modules that depend on that module for the auto". |
| Dependencies come from the build files, not from Gradle. | The AI's choice. tb does not have to run Gradle to find them. |
| You can still go deep by hand. | "go deep into your commands, deep into your modules, and define manually how every command should run." |
| The task list lives in `.tb`, in the project. | "can this be used in any android project?" |
| `tb print` and `tb run` never open the menu. | "something AI can consume without having to run the tool perse". |
| `runner:` line. | "designed for usage with Gradle but this can be used with anything else". |
| Tests with a fake Gradle project and a fake fzf. | You asked for tests. The tests run with no Gradle, no Android SDK and no terminal. |
| The Unlicense. | You asked for a license. Copy it, do whatever you want with it. |

## What we changed on the way

- **The name.** gboard. Then "command center", command `cc`. `cc` is already the C compiler. Then **Task Board**, command `tb`.
- **The README.** "you're kind of overdescribing these things". We rewrote it as a manual: short lines, the same words every time.
- **The screenshots.** First, one screenshot per row. Then, no pictures: "Just remove the images." The row text is in `code`.
- **Install.** First an install script. Then Homebrew: `brew install cicerohellmann/tap/tb`.
- **Affected modules.** First Auto ran only on the changed modules. After we looked at tools like this one, Auto also runs on the modules that depend on them.
- **Review.** "I want some sub-agents to scrutinize the readme." AI agents checked the README against the code.

## Other people's code

We did not open other people's code while building tb.
The AI wrote it from what it knows about fzf, Gradle, git and bash.
What it knows comes from other people: their docs, their code, their answers online. The AI learned from them.
The AI can't say which ones. The References below are the docs for each tool tb uses.

## Tools like this one

We looked for tools like tb while it was being built. We did not want to make something that already exists.

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
