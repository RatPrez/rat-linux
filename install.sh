#!/usr/bin/env bash
# Orchestrator. Sources lib/common.sh then runs install/*.sh in numeric order.
#
# Usage:
#   ./install.sh                 # run all modules
#   ./install.sh 06-gpu          # run one module (substring match)
set -euo pipefail

RAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAT_DIR
# shellcheck source=lib/common.sh
source "$RAT_DIR/lib/common.sh"
# shellcheck source=lib/ui.sh
source "$RAT_DIR/lib/ui.sh"
# shellcheck source=lib/patches.sh
source "$RAT_DIR/lib/patches.sh"

require_not_root
ui_intro
sudo_keepalive

filter="${1:-}"
shopt -s nullglob
modules=("$RAT_DIR"/install/[0-9]*.sh)

[[ ${#modules[@]} -gt 0 ]] || die "No modules found in $RAT_DIR/install/"

# Filter up front so the progress bar's total matches what actually runs.
if [[ -n "$filter" ]]; then
  filtered=()
  for module in "${modules[@]}"; do
    [[ "$(basename "$module" .sh)" == *"$filter"* ]] && filtered+=("$module")
  done
  modules=("${filtered[@]}")
  [[ ${#modules[@]} -gt 0 ]] || die "No module matches '$filter'."
fi

# Every optional prompt happens here, before ui_init carves out its scroll
# region. The category picker is a full gum TUI and cannot share the terminal
# with the scroll region, so it's pulled out of the module loop and sourced
# directly; the loop below skips it.
for i in "${!modules[@]}"; do
  if [[ "$(basename "${modules[$i]}" .sh)" == "03-category-picker" ]]; then
    log "Module: 03-category-picker"
    # shellcheck source=/dev/null
    source "${modules[$i]}"
    unset 'modules[i]'
  fi
done
modules=("${modules[@]}")

ui_init "${#modules[@]}"

step=0
for module in "${modules[@]}"; do
  name="$(basename "$module" .sh)"
  log "Module: $name"
  ui_step "$step" "$name"
  # shellcheck source=/dev/null
  source "$module"
  step=$((step + 1))
  ui_progress "$step" "$name"
done

# Restore the plain terminal before anything below prints; run_pending_patches
# does its own `clear`, which would fight the scroll region.
ui_cleanup

# A fresh install runs every patch that exists, since a patch may be a real
# system change rather than a migration. See patches/README.md.
[[ -z "$filter" ]] && run_pending_patches

summary=()
if [[ ${#RAT_FAILED_PKGS[@]} -gt 0 ]]; then
  summary+=("${#RAT_FAILED_PKGS[@]} package(s) failed and were skipped:")
  for p in "${RAT_FAILED_PKGS[@]}"; do
    summary+=("  - $p")
  done
  summary+=("" "Re-run after fixing them, or install them by hand.")
else
  summary+=("No package failures.")
fi
summary+=("" "Reboot into the Plasma (Wayland) session when ready:" "  sudo reboot")

ui_box "rat-linux install complete" "${summary[@]}"
