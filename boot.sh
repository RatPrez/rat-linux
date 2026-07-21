#!/usr/bin/env bash
# Tiny bootstrap. This is the only thing you curl.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/RatPrez/rat-linux/main/boot.sh)
#
# It installs git, clones the repo, then hands off to install.sh.
set -euo pipefail

RAT_REPO="${RAT_REPO:-https://github.com/RatPrez/rat-linux.git}"
RAT_BRANCH="${RAT_BRANCH:-main}"
RAT_DIR="${RAT_DIR:-$HOME/.local/share/rat-linux}"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Don't run this as root. Run as your normal user." >&2
  exit 1
fi

command -v git >/dev/null 2>&1 || sudo pacman -Sy --needed --noconfirm git

if [[ -d "$RAT_DIR/.git" ]]; then
  echo "==> Updating existing checkout in $RAT_DIR"
  git -C "$RAT_DIR" pull --ff-only
else
  echo "==> Cloning $RAT_REPO -> $RAT_DIR"
  rm -rf "$RAT_DIR"
  git clone --branch "$RAT_BRANCH" "$RAT_REPO" "$RAT_DIR"
fi

exec bash "$RAT_DIR/install.sh" "$@"
