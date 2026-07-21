#!/usr/bin/env bash
# Install the yay AUR helper if missing.

if command -v yay >/dev/null 2>&1; then
  ok "yay already installed"
else
  log "Building yay from the AUR"
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  ( cd "$tmpdir/yay" && makepkg -si --noconfirm )
  rm -rf "$tmpdir"
  ok "yay installed"
fi
