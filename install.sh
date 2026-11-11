#!/usr/bin/env bash
# Installs gboard into ~/.local/bin (or $GBOARD_BIN), and fzf too if it's missing or older than 0.46.
#   curl -fsSL https://raw.githubusercontent.com/cicerohellmann/gboard/main/install.sh | bash
# or, from a clone: ./install.sh
set -euo pipefail

bin=${GBOARD_BIN:-$HOME/.local/bin}
mkdir -p "$bin"
for tool in git curl; do command -v "$tool" > /dev/null || { echo "gboard needs $tool. Install it first."; exit 1; }; done

fzf_ok() {
  command -v fzf > /dev/null || return 1
  fzf --version | awk '{ split($1, x, "."); exit !(x[1] > 0 || x[2] >= 46) }'
}

if fzf_ok; then
  echo "✔ fzf $(fzf --version | awk '{ print $1 }')"
elif command -v brew > /dev/null; then
  echo "Installing fzf with Homebrew..."
  brew install fzf || brew upgrade fzf
else
  # Distro packages are often too old, so take fzf's own latest release
  echo "Installing fzf into ~/.fzf..."
  if [ -d "$HOME/.fzf/.git" ]; then git -C "$HOME/.fzf" pull -q; else git clone -q --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"; fi
  "$HOME/.fzf/install" --bin > /dev/null
  ln -sf "$HOME/.fzf/bin/fzf" "$bin/fzf"
fi

here=$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2> /dev/null && pwd || true)
if [ -n "$here" ] && [ -f "$here/gboard" ] && [ -f "$here/install.sh" ]; then
  cp "$here/gboard" "$bin/gboard"
else
  curl -fsSL https://raw.githubusercontent.com/cicerohellmann/gboard/main/gboard -o "$bin/gboard"
fi
chmod +x "$bin/gboard"
echo "✔ gboard installed in $bin"

case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo; echo "Add $bin to your PATH, e.g. in ~/.zshrc or ~/.bashrc:"; echo "  export PATH=\"$bin:\$PATH\"" ;;
esac
PATH="$bin:$PATH"
fzf_ok || echo "⚠ An older fzf comes first on your PATH ($(command -v fzf)). Put $bin before it."
echo "Run gboard inside any project with ./gradlew. gboard help lists the commands for scripts and AI agents."
