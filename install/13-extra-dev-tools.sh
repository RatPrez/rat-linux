#!/usr/bin/env bash
# Optional: extra dev tools that aren't needed day-to-day (HeidiSQL + its Qt6
# port, Ghidra). Installed via yay, which handles both AUR and official-repo
# packages transparently, since packages/extra-dev-tools.txt mixes the two.
#
# Prompted y/N by default. Set RAT_EXTRA_DEV_TOOLS=yes (or =no) to skip the
# prompt on unattended runs.

answer="${RAT_EXTRA_DEV_TOOLS:-}"

if [[ -z "$answer" ]]; then
  if [[ -r /dev/tty ]]; then
    printf 'Install extra dev tools (HeidiSQL, Ghidra)? [y/N] ' > /dev/tty
    read -r answer < /dev/tty || answer=""
  else
    warn "No TTY to prompt on; skipping extra dev tools. Set RAT_EXTRA_DEV_TOOLS=yes to force."
    answer="no"
  fi
fi

case "${answer,,}" in
  y|yes)
    count="$(read_list "$RAT_DIR/packages/extra-dev-tools.txt" | grep -c . || true)"
    log "Installing $count extra dev tool(s) (failures are skipped, not fatal)"
    aur_install < <(read_list "$RAT_DIR/packages/extra-dev-tools.txt")
    ok "Extra dev tools processed"
    ;;
  *)
    ok "Skipping extra dev tools."
    ;;
esac
