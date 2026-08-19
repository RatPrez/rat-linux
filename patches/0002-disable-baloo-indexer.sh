#!/usr/bin/env bash
# CHANGELOG: Disable the baloo file indexer (baloo_file / baloo_file_extractor), which was pegging a core and causing UI lag
# CHANGELOG: Mask kde-baloo.service (systemd --user) so it doesn't restart itself on next login
# CHANGELOG: Kill any baloo_file / baloo_file_extractor processes already running

if ! command -v balooctl6 >/dev/null 2>&1; then
  ok "balooctl6 not found (baloo not installed); nothing to disable"
  return 0
fi

log "Disabling baloo file indexing"
balooctl6 disable

if systemctl --user list-unit-files kde-baloo.service >/dev/null 2>&1; then
  log "Masking kde-baloo.service (systemd --user)"
  systemctl --user mask --now kde-baloo.service >/dev/null 2>&1 \
    || warn "Couldn't mask kde-baloo.service."
fi

pkill -f '/baloo_file(_extractor)?$' 2>/dev/null || true

ok "Baloo indexer disabled"
