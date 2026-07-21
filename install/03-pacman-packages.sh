#!/usr/bin/env bash
# Install everything from packages/pacman.txt.

mapfile -t pkgs < <(read_list "$RAT_DIR/packages/pacman.txt")
log "Installing ${#pkgs[@]} pacman packages"
sudo pacman -S --needed --noconfirm "${pkgs[@]}"
ok "pacman packages installed"
