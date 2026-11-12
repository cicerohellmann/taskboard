<h1><img src="docs/banner.png" alt="Task Board (tb)" width="300"></h1>

[![tests](https://github.com/cicerohellmann/taskboard/actions/workflows/test.yml/badge.svg)](https://github.com/cicerohellmann/taskboard/actions/workflows/test.yml)

![tb: ticking unit tests on the changed modules, clean and the auto tasks, then running them](demo/demo.gif)

Task Board (`tb`) is a menu for Gradle tasks. You tick the tasks, pick the modules and the test classes, and tb runs them all in one command.

I've always had trouble with long custom commands that always keep changing, specially in big projects.

## Docs

| Doc | What is in it |
|---|---|
| [README.md](README.md) | How to install tb and how to use it. |
| [MANUAL.md](MANUAL.md) | Every detail: the `.tb` file, the menu row by row, the keys, the step order, the commands for scripts, the [known issues](MANUAL.md#known-issues). |
| [CHANGELOG.md](CHANGELOG.md) | What changed in each version. |
| [docs/AI.md](docs/AI.md) | For AI agents: how to run tb and how to set up `.tb`. |
| [docs/WORDS.md](docs/WORDS.md) | For people who write these docs: the words to use. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to change tb and run its tests. |
| [HOW-WE-BUILT-IT.md](HOW-WE-BUILT-IT.md) | What we thought about, what we changed, similar tools and references. |

## Install

tb needs `bash`, `git` and [fzf](https://github.com/junegunn/fzf) 0.46 or newer.

With Homebrew (macOS or Linux). Homebrew installs fzf too:

```sh
brew install cicerohellmann/tap/tb
```

Without Homebrew:

```sh
curl -fsSL https://raw.githubusercontent.com/cicerohellmann/taskboard/main/install.sh | bash
```

The installer puts `tb` in `~/.local/bin` (set `TB_BIN` for another folder). If fzf is missing or older than 0.46, it installs fzf too. It needs `curl` and `git`.

## Update

With Homebrew:

```sh
brew update
brew upgrade tb
```

Without Homebrew, run the install command again. It replaces the old `tb`:

```sh
curl -fsSL https://raw.githubusercontent.com/cicerohellmann/taskboard/main/install.sh | bash
```

Updating replaces only the `tb` script. Your `.tb` file, presets and history stay as they are.

To see your version with Homebrew: `brew list --versions tb`. [CHANGELOG.md](CHANGELOG.md) lists what changed in each version.

## Use it

Type `tb` in a project with `./gradlew`. The menu opens. There are two ways to use it.

### Auto

Auto runs the tasks marked `auto` in your `.tb` file. It runs them on the modules changed on your branch, and on the modules that depend on them. Tasks that run on the whole project, like `detekt`, run once.

- In the menu: tick `★ Auto`, then tick `▶ Run`.
- From the shell: `tb run auto`.
- If no module changed, Auto runs nothing.

### By hand

Pick tasks, modules and test classes yourself.

1. Tick a task with ENTER.
2. For a module task, the modules screen opens. Tick the modules with TAB, then ENTER.
3. For a test task, the test classes screen opens. Tick the test classes with TAB, then ENTER.
4. Tick more tasks. Then tick `▶ Run` and `✔ Confirm, run it`.

ESC goes back. [MANUAL.md](MANUAL.md#the-menu-row-by-row) explains every row and key.

## Set it up for your project

The task list is a `.tb` file in the project root. `tb init` writes it from your project's own tasks.

1. Run `tb init` in the project. It asks Gradle for every task of every module. This takes a few seconds.
2. It shows a list to tick:
   - Tasks you ran before from your shell history, with `★` and the number of runs. Ticked.
   - Common Android tasks your project has: lint, detekt, ktlint, unit tests, Paparazzi, APK builds, clean. Ticked.
   - Every other task. Type to search them. Not ticked.
3. TAB ticks or unticks a task. CTRL-T turns `auto` on or off. Checks and tests are `auto` at the start.
4. ENTER writes `.tb`. If there is a `.tb` already, it is saved as `.tb.bak`, and its lines that are not in the list are kept.
5. Check it with `tb list`.
6. Commit `.tb`. Your team uses the same task list.

`tb init --defaults` writes the built-in task list without asking. Without a `.tb` file, tb uses the built-in task list.

Editing `.tb` by hand is optional. To let an AI agent write `.tb` for you, see [docs/AI.md](docs/AI.md#set-up-tb-for-a-project).

### Write .tb by hand

One task per line. The columns are separated by `|`. Lines that start with `#` are comments.

```
# step | label                    | task              | where  | auto
1      | Clean                    | clean             | root
3      | Detekt (static analysis) | detekt            | root   | auto
3      | Android lint             | lintDebug         | module | auto
4      | Unit tests               | testDebugUnitTest | module | auto
5      | Build debug APK          | assembleDebug     | :app
```

| Column | What to write |
|---|---|
| step | When the task runs, 1 to 6: 1 clean, 2 formatting, 3 checks, 4 tests, 5 builds, 6 reports. |
| label | The name in the menu. |
| task | The Gradle task. |
| where | `module`: you pick the modules. `root`: the whole project. `:app`: always the module `:app`. |
| auto | `auto` if Auto should run it. Empty if not. |

[example/.tb](example/.tb) is a full example. [MANUAL.md](MANUAL.md#the-tb-file) has the details.

## Try it on the demo project

To try tb before you set it up on your own project, make the demo project from the GIF. It is made by a script in this repo:

```sh
git clone https://github.com/cicerohellmann/taskboard.git
cd taskboard
demo/make-project.sh /tmp/tb-demo
cd /tmp/tb-demo
tb
```

The demo project has changed files in `:garden` and `:notes:editor`, so Auto has modules to run on. Its `./gradlew` only prints the task names, and it gives `tb init` a made-up task list.

## License

[The Unlicense](LICENSE). Copy it, change it, sell it, do whatever you want with it.
