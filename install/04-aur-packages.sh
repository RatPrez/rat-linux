#!/usr/bin/env bash
# Install everything from packages/aur.txt via yay.

mapfile -t pkgs < <(read_list "$RAT_DIR/packages/aur.txt")
if [[ ${#pkgs[@]} -eq 0 ]]; then
  ok "no AUR packages listed"
  return 0 2>/dev/null || exit 0
fi
log "Installing ${#pkgs[@]} AUR packages"
yay -S --needed --noconfirm "${pkgs[@]}"
ok "AUR packages installed"
