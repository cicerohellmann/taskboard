# How we built it

## The problem

I've always had trouble with long custom commands that always keep changing, specially in big projects.

The first ask was a "DJ board": all the commands in one place, and a list to pick the modules each command runs on. "Cause its so hard for me to remember".

## Words used below

- **Task.** One Gradle task, like `lintDebug` or `clean`. The project's tasks are listed in a `.tb` file.
- **Module task.** A task that runs per module, like unit tests. When you open it, tb shows a list of the project's modules to pick from.
- **Whole-project task.** A task that runs once for the whole project, like `clean`. It has no module list.
- **Step.** A number from 1 to 6 on each task in `.tb`. It sets the order the tasks run in.
- **Auto.** The `★ Auto` row on the main menu. It finds the modules changed on your branch and runs the standard checks on them.

## What we thought about

Each line is something the author asked for, and what was built for it. Quotes are the author's words. "AI's choice" means the author did not ask for it.

| What the author asked | What was built |
|---|---|
| "could we have like a DJ board like an app or a plugin were we could have all commands that can be ran?" | AI's choice: a menu in the terminal, made with fzf, instead of an app or a plugin. The author kept using it, so it stayed. |
| "when we want to run commands that could be module specific, like we could click, open a list and select which modules we want to run them" | Open a module task and tb shows the project's modules. Tick the ones the task should run on. |
| "I want to run more commands simultaneously and I want to see the loading bar as the command runs" | You can tick several tasks. tb puts them all in one Gradle command and runs it once. It runs Gradle with `--console=rich`, which shows Gradle's progress bar. |
| "I want the first option to be "Press Enter to Run" and then inside I want to have Confirm/Cancel in case you accidentally press it twice." | The main menu has a `▶ Run` row. It opens a screen with Cancel and Confirm, so pressing Enter twice by accident does not start a build. |
| "a button when you go back to this menu and you have any selection, to save it as a preset" | `💾 Save as preset` asks for a name and saves the ticked tasks and their modules. Presets are listed at the top of the main menu. Opening one shows "Run it" and "Delete preset". Delete asks you to confirm. |
| "if I open the same command I pressed before, you should continue on the addition logic … I would like to see some sort of marker showing the commands that are already added" | Tasks already added show a `✓` and their modules on the main menu. Open one again and its modules are already ticked, so you can add more. |
| "Another command that would be cool is auto-select modified modules. It looks into the Git folders and just auto-selects modules that were modded and then creates this command list." | The `★ Auto` row. It compares your branch with main, finds the modules with changed or new files, and adds the standard checks on those modules. |
| "You can use the general auto runner that would pack all the standard tools that you define." | In `.tb`, a task can be marked `auto`. Those are the standard checks Auto adds. `tb run auto` does the same without the menu. |
| "There are too many clicks, too many options. I like the way it was in the beginning. I just want to add what I described on top of the way it was in the beginning." | A later version had more screens. It was rolled back to the first version, and the new features were added on top. The path is: main menu, a task, its modules, its test classes, back to the main menu. |
| "For Ktlint Check and Format when I press those commands individually, I don't want to go into picking the modules detail." "They don't have any granularity so you just checkbox them at root level." | Whole-project tasks have no module screen. Press Enter on one in the main menu and it is ticked there. |
| "How do we guarantee order here?" | Each task in `.tb` has a step: 1 clean, 2 tasks that change files (like formatting), 3 checks, 4 tests, 5 build, 6 reports. tb runs the tasks in step order, whatever order you ticked them in. The numbers are the AI's choice. |
| Same question. | AI's choice: tasks in steps 1 and 2 run as their own Gradle command first, then the rest. tb runs Gradle with `--parallel`, and without this Gradle could start the checks while clean or formatting is still changing files. |
| "when I press the selectable comments, the window blinks and my arrow goes up. I want my arrow to continue on top of the selection I made." | Ticking a whole-project task updates the menu in place. The menu does not close and open again, and the cursor stays on the row. |
| "check the modules that depend on that module for the auto" | Auto also runs on the modules that depend on a changed module, directly or through other modules. |
| No ask. | AI's choice: tb finds which module depends on which by reading each module's build file. It does not ask Gradle, so it does not have to run Gradle for this. |
| "I couldn't just go inside of the unit tests and then select all modules that were modified and related." | The modules screen has a `◆ CHANGED AND DEPENDENT MODULES` row that ticks all of them at once. Changed modules are marked `★`, modules that depend on them `☆`. AI's choice: CTRL-A ticks every module shown. |
| "…define manually how every command should run." | Auto is the quick path. You can still open each task and pick its modules and test classes yourself. |
| "can this be used in any android project?" | The task list moved out of the script into a `.tb` file in the project. `tb init` writes one to start from. |
| "something AI can consume without having to run the tool perse and using it as a go to location for commands to run?" | `tb print` prints the command and `tb run` runs it. Neither opens the menu. `tb agents` prints a note to paste into AGENTS.md or CLAUDE.md. |
| "a prompt suggestion to look into the command history of the project and do the auto setup" | [docs/AI.md](docs/AI.md) has a prompt to paste into an AI agent. The agent reads the shell history and CI files and writes `.tb`. |
| "We should also have a -h that explains what it does." | `tb -h` (or `tb help`) says what tb is and lists its commands. |
| "Make it clear this was designed for usage with Gradle but this can be used with anything else." | A `runner:` line in `.tb` replaces `./gradlew` with another tool, like `make` or `just`. Without Gradle there are no modules, so every task runs on the whole project. |
| "I can't stress it more, I want tests" | `tests/run.sh` builds a small fake Gradle project and swaps fzf for a script that presses the keys. The tests run with no Gradle, no Android SDK and no terminal. |
| "I also want a license to enable anyone to copy this and do whatever they want with it." | The AI picked the Unlicense because it does that: anyone can copy, change and sell the code. |

## Where things are kept

- `.tb`, in the project root: the project's own task list. Without it, tb uses `~/.config/tb/commands`, then a built-in Android list.
- `~/.config/tb/presets/<project folder>/`: presets.
- `~/.tb_history`: the commands tb ran.
- `~/.cache/tb/`: the module list, and the tasks of each module.

## What we changed on the way

- **The name.** It was gboard. The author asked for "command center" with the command `cc`, then: "hmmm, what about task board? tb?" It is **Task Board**, command `tb`.
- **The README.** "I think you're kind of overdescribing these things too." It was rewritten as a manual: short lines, the same words every time.
- **The screenshots.** The author asked for "one screenshot per row of the commands", so the README got pictures of the menu. They came out as big blocks, not one per row. The author wanted "a per-line thing", then said: "Just remove the images. Just explain every line but make it look a little bit different". Now each row is shown as `code` text, with a line that explains it.
- **Install.** First an install script. Then Homebrew, after the author said "everyone uses Homebrew on macOS": `brew install cicerohellmann/tap/tb`. Homebrew installs fzf too.
- **A crash.** Auto crashed with a "Broken pipe" error. "Also before you publish anything, just check if every command works because it just crashed." The crash was fixed.
- **Affected modules.** At first, Auto ran only on the changed modules. The author asked "is there anything like this tool out there?" The search found Gradle plugins that also find the modules that depend on the changed ones. The author then asked: "check the modules that depend on that module for the auto". So Auto now also finds the modules that depend on the changed modules, and runs there too.
- **Review.** "I want some sub-agents to scrutinize the readme." AI agents checked the README against the code.
- **Field test.** A field test found seven bugs. They are fixed in 0.3.0. [CHANGELOG.md](CHANGELOG.md) lists them, and the known issues that are not fixed yet.
- **tb init reads the project.** Up to 0.3.0, `tb init` wrote the same list in every project. In 0.4.0 it asks Gradle for every task with an init script, and offers the tasks from the shell history and the common Android tasks first. The same task list fixes a known issue: tb knows which modules have a task.
- **Real terminal.** The author asked that `tb init` be tested "in a REAL terminal with REAL fzf, not only with fake fzf". `tests/tty.sh` runs tb in tmux with the real fzf. On the real terminal, a search in `tb init` kept the rows in list order, so the best match was not on top. Fixed before the release: fzf sorts the search results.

## Other people's code

We did not look at other people's code to build tb.
The AI wrote it from what it already knew about fzf (and refuses to understand that "what it already knows" comes from other people, just fantastic), Gradle, git and bash.

## Tools like this one

What we searched: web search for "interactive task runner", "TUI to select and run tasks across monorepo packages", "fzf for npm scripts / make / bazel targets", "run tests for changed packages and dependents", "affected packages" for JS/TS, Rust, Go, Python, Maven, Gradle, Bazel, Pants and Buck2; the JetBrains Marketplace (search for "gradle task", "affected", "changed modules", "run tests changed", "task runner", "multirun", "monorepo", "favorites"); the IntelliJ and Android Studio docs; the Develocity docs; and VS Code extensions.

Short answer: no tool we found does the whole thing, for Gradle or for any other builder. The tools fall into five groups:

- **Pickers.** A menu to pick a task and run it. Most pick one task. None pick modules per task, test classes, or changed modules.
- **Monorepo runners.** Nx, Turborepo, moon and others run a task on the changed packages and their dependents. You choose with flags, not a menu, and you adopt the runner.
- **Affected detectors.** One per builder. They find changed modules and their dependents. They have no menu.
- **IDE plugins.** Saved runs and task lists in the IDE. No changed modules, no script mode.
- **Develocity.** Picks test classes with a model on a server. No menu, Gradle and Maven only, paid.

tb sits between the pickers and the affected detectors.

### Pickers in the terminal

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [fnug](https://github.com/nickolaj-jepsen/fnug) | TUI that ticks lint and test commands from git changes, runs them side by side. `fnug check` runs them with no TUI. MCP server for agents. | Closest tool. Any language. Each command in its own terminal pane. Parallel runs. File watching. Pre-commit hook. | Modules per task. Test classes. Dependents: fnug matches file paths, it does not follow the dependency graph. Presets. |
| [lazygradle](https://pypi.org/project/lazygradle/) | A terminal UI to browse and run Gradle tasks. | Reading the output. Saved runs with flags and env vars. History. | Several tasks at once, modules per task, test classes, changed modules, step order, script mode. |
| [fzf-make](https://github.com/kyu08/fzf-make) | fzf picker for make, npm, pnpm, yarn, just and task. Reads npm, pnpm and yarn workspaces. | Preview of the target. Workspace scripts. History. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [rt](https://github.com/unvalley/rt) | Picks a task from make, just, task, cargo-make, mise or mask and runs it. | Many runners, no config. Asks for recipe parameters. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [ntl](https://github.com/ruyadorno/ntl) | Menu for `package.json` scripts. `--multiple` ticks several. `--ordered` runs them in pick order. | Reruns the last task with `nt`. | Workspaces. Modules, test classes, changed modules. Presets. |
| [prw](https://github.com/nyatinte/prw) | Picks a pnpm workspace package, then a script, and runs it. | Fuzzy search. Often used packages first. | Several tasks or packages at once. Changed packages. Test classes. |
| [launch-goblin](https://github.com/svjson/launch-goblin) | TUI to pick modules and launch `turbo run`, npm, pnpm or docker compose targets. Shared and private launch configs. `--relaunch` reruns the last set. | Long-running dev servers. Docker compose. | Gradle. Test classes. Changed modules. Script mode. |
| [nur](https://pypi.org/project/nur/) | Finds tasks from many runners. Runs them from a menu or the shell. | Many runners, no config. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [task-runner-detector](https://docs.rs/crate/task-runner-detector/latest) | Finds runner configs in a folder. Picks one task and runs it. | JSON output. | Gradle. Several tasks at once. Modules, test classes, changed modules. |
| [mise run](https://mise.jdx.dev/cli/run.html) | With no task name, opens a task picker in a terminal. | Part of a tool many people have. | One task. Modules, test classes, changed modules. |
| [just `--choose`](https://github.com/casey/just) | Picks recipes from a justfile with fzf. | Nothing for Gradle. | Gradle. Modules, test classes, changed modules. |
| [gradle-fzf-completion](https://github.com/donat/gradle-fzf-completion), [fzf-gradle-tasks](https://github.com/tom-power/fzf-gradle-tasks) | zsh: TAB after `./gradlew` picks a task with fzf. | Works inside the normal shell prompt. | Everything after picking one task name. |
| [fzf-bazel](https://blog.jez.io/fzf-bazel) | Blog post: `bazel query` piped into fzf for TAB completion of targets. | Bazel. | Everything after picking a target. |

### Monorepo runners with "affected"

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [Nx affected](https://nx.dev/docs/features/ci-features/affected), [Nx terminal UI](https://nx.dev/docs/kb/terminal-ui) | Runs tasks on changed projects and the projects that depend on them. Works with Gradle through a plugin. The terminal UI shows running tasks. | Picks tasks by their inputs. Cache. Parallel runs. Output per task. | A menu to pick tasks and projects: the terminal UI only shows tasks you already started. Test classes. You don't have to adopt Nx. |
| [Turborepo `turbo run`](https://turborepo.dev/docs/reference/run) | `--affected` runs on packages changed on the branch. `--filter` picks packages. `--ui tui` shows output. | Cache. Parallel runs. | A menu to pick tasks and packages. Gradle. Test classes. |
| [moon](https://moonrepo.dev/docs/commands/query/affected) | `moon run :test --affected`. `moon query affected` lists affected projects and tasks. | Many languages. Cache. | A menu. Gradle. Test classes. |
| [pnpm `--filter`](https://pnpm.io/filtering) | `--filter "...[origin/main]"` runs a script on changed packages and their dependents. | Built into pnpm. | A menu. Presets. Test classes. |
| [Lerna `--since`](https://lerna.js.org/docs/api-reference/commands) | `lerna run test --since main` runs on packages changed since a ref. | Built into Lerna. | A menu. Presets. Test classes. |
| [Rush `--impacted-by`](https://rushjs.io/pages/advanced/incremental_builds/) | Builds a project and the projects that depend on it. | Built into Rush. | A menu. Changed modules found from git. Test classes. |
| [Pants `--changed-since`](https://www.pantsbuild.org/dev/reference/subsystems/changed) | `pants --changed-since=origin/main --changed-dependents=transitive test`. | Target-level graph. Many languages. | A menu. Presets. You don't have to adopt Pants. |

### Affected detectors, one per builder

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [AffectedModuleDetector](https://github.com/dropbox/AffectedModuleDetector) (Dropbox, archived) | Gradle plugin. Runs tests on changed modules and the modules that depend on them. | Follows the dependency graph. Runs inside Gradle, good for CI. | A menu. Test classes. Presets. |
| [affected-module-detector](https://github.com/danielriverolosa/affected-module-detector) (danielriverolosa) | Gradle plugin. Lists the affected tasks, dependents included. | Follows the dependency graph. A test-only change does not spread. A build-logic change hits every module. | A menu. Test classes. Presets. Works with other runners. |
| [affected-tests](https://github.com/vedanthvdev/affected-tests) | Gradle plugin. `./gradlew affectedTest` runs the tests linked to the branch changes. `--explain` prints why. | Picks tests, not whole modules. Falls back to the full suite on unknown files. | A menu. Other task types. Presets. |
| [dag-command](https://github.com/leandroBorgesFerreira/dag-command) | Gradle plugin. Writes the affected modules and the graph as JSON or CSV. | Follows the dependency graph. Machine-readable output. | Runs tasks. A menu. Test classes. |
| [change-tracker-plugin](https://github.com/ismaeldivita/change-tracker-plugin) (archived) | Gradle plugin. Adds `<task>ChangedModules` tasks. | Follows the dependency graph. | A menu. Test classes. Presets. |
| [gitflow-incremental-builder](https://github.com/gitflow-incremental-builder/gitflow-incremental-builder) | Maven extension. Builds and tests the modules changed against a branch, and their dependents. | Maven. Runs inside the build. | A menu. Test classes. Presets. |
| [cargo-test-changed](https://docs.rs/crate/cargo-test-changed/latest), [cargo-rail](https://github.com/loadingalias/cargo-rail) | Cargo: test the changed crates, optionally their dependents. cargo-rail explains why each crate is tested. | Rust. Reads Cargo metadata. | A menu. Other task types. Presets. |
| [gta](https://github.com/digitalocean/gta) | Go: lists packages changed on a branch and the packages that depend on them. | Go. | Runs tasks. A menu. |
| [difftrace](https://pypi.org/project/difftrace/) | uv workspaces: packages changed directly or through dependencies. | Python. | Runs tasks. A menu. |
| [bazel-diff](https://github.com/Tinder/bazel-diff), [target-determinator](https://github.com/bazel-contrib/target-determinator) | Bazel: targets affected between two git commits. | Exact, from target hashes. | Runs tasks. A menu. |
| [buck2-change-detector](https://github.com/facebookincubator/buck2-change-detector) | Buck2: maps changed files to changed targets. | Buck2. | Runs tasks. A menu. |
| [affected](https://github.com/Rani367/affected) | One CLI for 16 builders (Cargo, npm, pnpm, Go, Python, Maven, Gradle, .NET and more). Finds affected packages and runs a command on them. No config to start. | Many builders in one tool. | A menu. Tasks per module. Test classes. Presets. |

### IDE: JetBrains Marketplace, IntelliJ and Android Studio

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [IntelliJ / Android Studio Gradle tasks](https://www.jetbrains.com/help/idea/work-with-gradle-tasks.html) | Gradle tool window, Run Anything (Ctrl twice, several tasks with spaces), saved run configurations, shortcuts per task. | The debugger. The IDE. | Modules per task, test classes, changed modules, step order, terminal and script mode. |
| [IntelliJ: run tests from the Commit window](https://www.jetbrains.com/help/idea/performing-tests.html) | Runs uncommitted test classes in a changelist. A run configuration can run as a commit check. | Built in. Git aware. | Changed modules and dependents. Tasks other than tests. We found no "run tests on changed modules" in Android Studio. |
| [Multirun](https://plugins.jetbrains.com/plugin/7248-multirun) | Groups run configurations and starts them with one click. | Reuses any run configuration. | Changed modules. Picking modules per run. Script mode. |
| [Runners Bar](https://plugins.jetbrains.com/plugin/34701-runners-bar) | Run configurations as tabs in a bar. Groups, shared with the team in `.idea/runnersBar.xml`. | One click. Team groups. | Building the command from picks. Changed modules. Test classes. |
| [GradleArtisan](https://plugins.jetbrains.com/plugin/28877-gradleartisan) | Tool window with all tasks from all modules, favorites per project, task templates with variables. | Favorites and templates in the IDE. | Several tasks in one run. Changed modules. Test classes. |
| [Gradle Commander](https://plugins.jetbrains.com/plugin/21059-gradle-commander) | Tab to pick a Gradle task for the project or a module and run it. | In Android Studio. | Several tasks. Changed modules. Test classes. |
| [Execute Gradle Task](https://plugins.jetbrains.com/plugin/8872-execute-gradle-task) | Runs a Gradle task from a module's context menu (last update 2021). | Right-click on a module. | Several modules. Changed modules. Presets. |
| [changed-tests-runner](https://plugins.jetbrains.com/plugin/25626-changed-tests-runner) | Runs JUnit tests changed in uncommitted files. | One click from the Tools menu. | Tests of changed source code. Dependents. Branch changes. Other tasks. |
| [NGM TestRunner](https://plugins.jetbrains.com/plugin/23022-ngm-testrunner) | Finds methods hit by local git changes through the call graph and runs their JUnit tests. | Method-level. | Gradle tasks. Modules. Presets. |
| [Nx Console](https://plugins.jetbrains.com/plugin/21060-nx-console) | Nx in the IDE (also [VS Code](https://nx.dev/docs/getting-started/editor-setup)). Shows tasks per project and runs them. | Graph view. | Gradle without Nx. Changed modules from a menu. |

### Develocity

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [Predictive Test Selection](https://docs.develocity.ai/predictive-test-selection) | Before a test task, asks the Develocity server which test classes to run. A model trained on past Build Scans picks them. Gradle and Maven. | Picks test classes for you, not whole modules. Learns from history. | A menu. Tasks other than tests. Free, no server. It needs a licensed server and 14 days of history. |
| [Test Distribution](https://docs.gradle.com/develocity/test-distribution) | Runs test classes on remote agents in parallel. | Speed on big suites. | Choosing what to run. |
| [Develocity IntelliJ plugin](https://plugins.jetbrains.com/plugin/27471-develocity) | Build timeline and test history in the IDE. | Seeing why a build is slow. | Running anything. |

Develocity has nothing about affected modules or picking tasks. It works at the test-class level.

### VS Code

| Tool | What it does | Better than tb at | tb does and it doesn't |
|---|---|---|---|
| [Gradle for Java (vscode-gradle)](https://github.com/microsoft/vscode-gradle) | Gradle tasks per project in a tree. Pinned tasks, recent tasks, run with arguments. | In VS Code. Pins with arguments. | Several tasks from picks. Changed modules. Test classes. |
| [Task Explorer](https://github.com/spmeesseman/vscode-taskexplorer) | Tree of tasks from npm, gradle, make, maven, ant and more. | Many runners. | Several tasks at once. Modules. Changed modules. |
| [pnpm vscode helper](https://www.github.com/LinbuduLab/pnpm-vscode-helper) | Pick a pnpm workspace package, then a script. | pnpm workspaces. | Several packages. Changed packages. |

### Where tb is weaker

- tb is Gradle only today. fzf-make, rt, nur, fnug and affected read many runners.
- tb reads the dependencies from the build files. The plugins ask Gradle. Dependencies added by plugins or convention plugins are found by the plugins, not by tb.
- A change in build logic (`buildSrc`, `build-logic`, the version catalog) does not make every module affected in tb. Some plugins do this.
- tb runs one Gradle command and shows its output in the terminal. fnug, the Nx terminal UI and lazygradle show output per task and keep it.
- tb has no cache. Nx, Turborepo and moon skip tasks whose inputs did not change.
- tb picks whole modules. Develocity Predictive Test Selection, affected-tests and NGM TestRunner pick only the tests linked to the change.
- tb has no file watching and no pre-commit hook setup. fnug has both.
- tb checks that a module has a task only when Gradle could list the tasks. See [Known issues](MANUAL.md#known-issues).

## References

The official docs for each tool tb uses.

| Tool | What tb uses it for | Reference |
|---|---|---|
| fzf | The menu: `--multi`, `--expect`, `--header-first`, `--with-nth`, `--delimiter`, `--print-query`, `--bind`. `FZF_SELECT_COUNT` is why tb needs fzf 0.46. | [fzf](https://github.com/junegunn/fzf), [fzf docs](https://junegunn.github.io/fzf/) |
| Gradle | `--continue`, `--parallel`, `--console=rich`, `-q projects`, `--init-script` to list every task. | [Gradle command-line interface](https://docs.gradle.org/current/userguide/command_line_interface.html) |
| Gradle | `--tests`: run the picked test classes. | [Gradle test filtering](https://docs.gradle.org/current/userguide/java_testing.html#test_filtering) |
| git | Changed files on the branch: `git merge-base`, `git diff --name-only`. | [git diff](https://git-scm.com/docs/git-diff), [git merge-base](https://git-scm.com/docs/git-merge-base) |
| git | New files not committed yet: `git ls-files --others`. | [git ls-files](https://git-scm.com/docs/git-ls-files) |
| bash | The script. | [Bash Reference Manual](https://www.gnu.org/software/bash/manual/) |
| Paparazzi | Screenshot test classes. | [Paparazzi](https://github.com/cashapp/paparazzi) |
| tmux | `tests/tty.sh`: runs tb in a real terminal and reads the screen. | [tmux](https://github.com/tmux/tmux/wiki) |
| vhs | The GIF. | [vhs](https://github.com/charmbracelet/vhs) |
| Homebrew | The `brew install` formula. | [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook), [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap) |
| GitHub Actions | The tests on every push. | [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) |
| AGENTS.md | The note `tb agents` prints. | [agents.md](https://agents.md) |
| The Unlicense | The license. | [unlicense.org](https://unlicense.org) |
