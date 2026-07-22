#!/usr/bin/env bash
# Orchestrator. Sources lib/common.sh then runs install/*.sh in numeric order.
#
# Usage:
#   ./install.sh                 # run all modules
#   ./install.sh 05-nvidia       # run one module (substring match)
#   RAT_SKIP="steam" ./install.sh  # (per-module env toggles, see modules)
set -euo pipefail

RAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAT_DIR
# shellcheck source=lib/common.sh
source "$RAT_DIR/lib/common.sh"

require_not_root

filter="${1:-}"
shopt -s nullglob
modules=("$RAT_DIR"/install/[0-9]*.sh)

[[ ${#modules[@]} -gt 0 ]] || die "No modules found in $RAT_DIR/install/"

for module in "${modules[@]}"; do
  name="$(basename "$module" .sh)"
  if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
    continue
  fi
  log "Module: $name"
  # shellcheck source=/dev/null
  source "$module"
done

if [[ ${#RAT_FAILED_PKGS[@]} -gt 0 ]]; then
  warn "The following ${#RAT_FAILED_PKGS[@]} package(s) failed and were skipped:"
  for p in "${RAT_FAILED_PKGS[@]}"; do
    printf '     - %s\n' "$p" >&2
  done
  warn "Re-run after fixing them, or install manually.  Everything else is done."
else
  ok "No package failures."
fi

ok "All done."
log "Reboot into the Plasma (Wayland) session when ready:  sudo reboot"
