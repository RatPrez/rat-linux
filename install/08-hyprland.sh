#!/usr/bin/env bash
# Optional: a bare-minimum Hyprland session (no dotfiles). KDE Plasma stays your
# primary desktop; this just adds a second session selectable at the SDDM login.
#
# Prompted y/N by default. Set RAT_HYPRLAND=yes (or =no) to skip the prompt on
# unattended runs.

answer="${RAT_HYPRLAND:-}"

if [[ -z "$answer" ]]; then
  if [[ -r /dev/tty ]]; then
    printf 'Install a bare-minimum Hyprland session (optional)? [y/N] ' > /dev/tty
    read -r answer < /dev/tty || answer=""
  else
    warn "No TTY to prompt on; skipping Hyprland. Set RAT_HYPRLAND=yes to force."
    answer="no"
  fi
fi

case "${answer,,}" in
  y|yes)
    log "Installing bare-minimum Hyprland"
    pac_install < <(read_list "$RAT_DIR/packages/hyprland.txt")
    ok "Hyprland installed. Pick 'Hyprland' at the SDDM session picker."
    ok "No dotfiles: it writes a default ~/.config/hypr/hyprland.conf on first launch."
    ;;
  *)
    ok "Skipping Hyprland (Plasma only)."
    ;;
esac
