# Contributing

## The files

| File | What it is |
|---|---|
| `tb` | The whole tool. One bash script. |
| `install.sh` | The installer. |
| `tests/run.sh` | The tests. |
| `tests/fake-fzf` | Stands in for fzf in the tests. It reads scripted key presses. |
| `example/.tb` | The full example task list. A test checks it. |
| `demo/make-project.sh` | Makes the demo project. |
| `demo/demo.tape` | Records `demo/demo.gif` with [vhs](https://github.com/charmbracelet/vhs). |

## Tests

```sh
tests/run.sh
```

- The last line must say `0 failed`.
- The tests use a fake Gradle project and a fake fzf.
- They need no Gradle, no Android SDK and no terminal.
- GitHub Actions runs them on Linux and macOS on every push.
- GitHub Actions also runs `install.sh` on a clean Linux machine.

## The demo GIF

```sh
demo/make-project.sh /tmp/tb-demo
vhs demo/demo.tape
```

## Docs

- Use the words in [docs/WORDS.md](docs/WORDS.md).
- [docs/WORDS.md](docs/WORDS.md#where-things-go) says which doc a change goes in.
- When you change a row or a key in `tb`, change [MANUAL.md](MANUAL.md) too.
- Write each change in [CHANGELOG.md](CHANGELOG.md).

## Releases

1. Add the version to [CHANGELOG.md](CHANGELOG.md), with the headings New, Fixed and Known issues.
2. Push `main`. Wait until the tests pass on GitHub Actions.
3. Tag the version, like `v0.3.0`, and push the tag.
4. Make a GitHub release from the tag. The notes are the version's section of CHANGELOG.md.
5. In [homebrew-tap](https://github.com/cicerohellmann/homebrew-tap), change `url` and `sha256` in `Formula/tb.rb` to the new tag's `.tar.gz`. Push.
