# tb for AI agents

This doc is for AI agents. It says how to use tb in a project, how to set up `.tb`, and how to work on the tb repo.

- [Use tb in a project](#use-tb-in-a-project)
- [Set up .tb for a project](#set-up-tb-for-a-project)
- [Work on the tb repo](#work-on-the-tb-repo)

## Use tb in a project

tb runs build tasks. The project's tasks are in `.tb` in the project root. Use those task names. Don't guess Gradle task names.

- These commands never open the menu, except `tb hist`. Don't run `tb hist`.
- `tb` with no terminal prints the help and exits with 0.

### Run the checks

```sh
tb run auto
```

- Runs the `auto` tasks on the changed modules and the modules that depend on them.
- `tb print auto` prints the same command. It does not run it.
- No changed modules: exits with 1.

### Run some tasks

```sh
tb print detekt testDebugUnitTest=changed
tb run detekt testDebugUnitTest=changed
```

- `tb print SPEC...` prints the command, in step order. It does not run it.
- `tb run SPEC...` runs it. It exits with the build's exit code.

SPEC is one of:

| SPEC | What it means |
|---|---|
| `task` | A whole-project or fixed-module task. Example: `detekt`. |
| `task=:a,:b` | A module task on modules `:a` and `:b`. The `:` is optional: `task=a,b`. |
| `task=ALL` | A module task on every module. |
| `task=changed` | A module task on the changed modules. |
| `task=affected` | A module task on the affected modules. |
| `auto` | The `auto` tasks. |
| `@name` | A preset. |

- A module task needs `=`. `tb print testDebugUnitTest` is an error.
- A task that is not in the task list goes to the build as it is, last.
- The same module task twice runs on both sets of modules: `lintDebug=:a lintDebug=:b` is `lintDebug=:a,:b`.
- A module that does not have the task is left out, with a note on stderr: `Skipped, no such task there: ...`.
- A whole-project or fixed-module task ignores `=modules`.
- An error exits with 1 and says what is wrong.

### Find names

| Command | What it prints |
|---|---|
| `tb list` | The runner, then the task list: step, task, where, auto, label. |
| `tb modules` | Every module. |
| `tb changed` | The modules with a changed file on this branch. |
| `tb affected` | The changed modules and the modules that depend on them. |
| `tb presets` | This project's presets, and the command each one runs. |
| `tb history` | This project's last 20 commands, without repeats, newest last. |
| `tb help` | The help. |

Full details: [MANUAL.md](../MANUAL.md#commands-for-scripts).

### Without tb

Use the runner from `tb list` (default `./gradlew`). Whole-project tasks go as they are. Module tasks go as `:module:task`. Steps 1 and 2 (clean, formatting) go in their own run before the rest.

## Set up .tb for a project

`tb init` on a terminal opens a list for a person to tick. Without a terminal, `tb init` writes the built-in task list for Android, the same as `tb init --defaults`. It is the same list in every project. You must edit `.tb` to match the project.

1. Find the build tasks the project uses:
   - the user's shell history (`~/.zsh_history`, `~/.bash_history`): `./gradlew` lines run in this project
   - CI workflow files (`.github/workflows`, `.gitlab-ci.yml`, `bitrise.yml` and similar)
   - build scripts and the plugins they apply (Detekt, Ktlint, Spotless, Paparazzi, Kover...)
   - README and CONTRIBUTING
2. Run `tb init --defaults`. Then rewrite `.tb` with those tasks. The format is in [MANUAL.md](../MANUAL.md#the-tb-file) and in the comments in `.tb`.
3. Mark as `auto` the standard checks someone should run before pushing: lint, static analysis, formatting checks, unit tests.
4. Don't add tasks the project doesn't have.
5. Check it with `tb list` and `tb print auto`.
6. Add the output of `tb agents` to the project's AGENTS.md or CLAUDE.md.

A person can paste this into Claude Code, Codex or another agent, inside their project:

```text
Set up tb (https://github.com/cicerohellmann/taskboard) for this project.

1. Find out which build commands this project uses:
   - my shell history (~/.zsh_history, ~/.bash_history): ./gradlew lines run in this project
   - CI workflow files (.github/workflows, .gitlab-ci.yml, bitrise.yml and similar)
   - build scripts and the plugins they apply (Detekt, Ktlint, Spotless, Paparazzi, Kover...)
   - README and CONTRIBUTING
2. Run `tb init --defaults`, then rewrite .tb with those tasks, following the format and comments in it.
   Mark the standard checks someone should run before pushing (lint, static analysis, formatting
   checks, unit tests) as `auto`. Don't add tasks the project doesn't have.
3. Check it with `tb list` and `tb print auto`.
4. Add the output of `tb agents` to AGENTS.md or CLAUDE.md.
```

## Work on the tb repo

| File | What it is |
|---|---|
| `tb` | The whole tool. One bash script. |
| `install.sh` | The installer. |
| `tests/run.sh` | The tests. |
| `tests/fake-fzf` | Stands in for fzf in the tests. |
| `tests/tty.sh` | The tests in a real terminal (tmux) with the real fzf. |
| `example/.tb` | The full example task list. A test checks it. |
| `demo/` | The demo project script and the GIF. |

- Run `tests/run.sh` after every change. The last line must say `0 failed`.
- When you change a menu or `tb init`, run `tests/tty.sh` too. It needs tmux and fzf.
- Some tests check the help text. `tb help` must stay 45 lines or less.
- Write the docs with the words in [docs/WORDS.md](WORDS.md).
- When you change a row or a key in `tb`, change [MANUAL.md](../MANUAL.md) too.
- [CONTRIBUTING.md](../CONTRIBUTING.md) has the rest.
