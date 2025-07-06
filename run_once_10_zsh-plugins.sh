#!/usr/bin/env bash
# run_once_10_zsh-plugins.sh
# Installs Z‑shell plugins, themes and supporting binaries used in ~/.zshrc.
set -euo pipefail

# --------------- helpers ------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }
brew_pkg_installed()  { brew list --formula "$1" &>/dev/null; }
brew_cask_installed() { brew list --cask   "$1" &>/dev/null; }

OMZ_DIR="${HOME}/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-${OMZ_DIR}/custom}"
mkdir -p "$ZSH_CUSTOM"/{plugins,themes}

# --------------- 1. Homebrew --------------------------------------------------
if ! command_exists brew; then
  echo "Installing Homebrew …"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew update --quiet

# --------------- 2. Base utilities -------------------------------------------
for pkg in git ripgrep fasd fzf; do
  brew_pkg_installed "$pkg" || brew install "$pkg"
done

# Install (or update) the fzf shell bindings non‑interactively.
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-bash --no-fish --no-update-rc

# --------------- 3. oh‑my‑zsh -------------------------------------------------
if [ ! -d "$OMZ_DIR" ]; then
  echo "Installing oh‑my‑zsh …"
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

clone_if_missing() {
  local repo="$1" dest="$2"
  if [ ! -d "$dest/.git" ]; then
    git clone --depth=1 "$repo" "$dest"
  else
    git -C "$dest" pull --ff-only
  fi
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
                 "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_if_missing https://github.com/romkatv/powerlevel10k.git \
                 "${HOME}/powerlevel10k"

echo "✅  Z‑shell plug‑ins and theme installed."
echo "   Restart your terminal (or run:  exec zsh ) to start using them."

