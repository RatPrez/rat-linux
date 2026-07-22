#!/usr/bin/env bash
# Install everything from packages/aur.txt via yay, one at a time so a single
# broken AUR build is skipped rather than aborting the batch.

count="$(read_list "$RAT_DIR/packages/aur.txt" | grep -c . || true)"
if [[ "$count" -eq 0 ]]; then
  ok "no AUR packages listed"
  return 0 2>/dev/null || exit 0
fi
log "Installing $count AUR packages (failures are skipped, not fatal)"
aur_install < <(read_list "$RAT_DIR/packages/aur.txt")
ok "AUR packages processed"
