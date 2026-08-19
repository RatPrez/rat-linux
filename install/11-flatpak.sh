#!/usr/bin/env bash
# Install everything from packages/flatpak.txt via flatpak, one at a time so a
# single failure is skipped rather than aborting the batch. Adds the Flathub
# remote first if it isn't already configured.

if ! command -v flatpak >/dev/null 2>&1; then
  warn "flatpak not installed; skipping Flatpak apps"
  return 0 2>/dev/null || exit 0
fi

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

count="$(read_list "$RAT_DIR/packages/flatpak.txt" | grep -c . || true)"
if [[ "$count" -eq 0 ]]; then
  ok "no Flatpak apps listed"
  return 0 2>/dev/null || exit 0
fi

log "Installing $count Flatpak app(s) (failures are skipped, not fatal)"
while IFS= read -r app; do
  [[ -n "$app" ]] || continue
  if flatpak install -y --noninteractive flathub "$app"; then
    ok "flatpak: $app"
  else
    warn "flatpak FAILED: $app  (skipping, continuing with the rest)"
    RAT_FAILED_PKGS+=("$app")
  fi
done < <(read_list "$RAT_DIR/packages/flatpak.txt")
ok "Flatpak apps processed"
