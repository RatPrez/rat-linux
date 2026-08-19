#!/usr/bin/env bash
# Orchestrator. Sources lib/common.sh then runs install/*.sh in numeric order.
#
# Usage:
#   ./install.sh                 # run all modules
#   ./install.sh 06-gpu          # run one module (substring match)
#   RAT_SKIP="steam" ./install.sh  # (per-module env toggles, see modules)
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

# Ask for the sudo password once up front, then keep the credential cache
# alive in the background for the rest of the run so none of the ~10 modules
# below prompt again (nothing is stored — this just refreshes sudo's own
# timestamp cache periodically so it can't expire mid-run).
sudo_keepalive

filter="${1:-}"
shopt -s nullglob
modules=("$RAT_DIR"/install/[0-9]*.sh)

[[ ${#modules[@]} -gt 0 ]] || die "No modules found in $RAT_DIR/install/"

# Filter down the module list up front so the progress bar's total matches
# what will actually run (e.g. `./install.sh 06-gpu` is "1 of 1", not "1 of 16").
if [[ -n "$filter" ]]; then
  filtered=()
  for module in "${modules[@]}"; do
    [[ "$(basename "$module" .sh)" == *"$filter"* ]] && filtered+=("$module")
  done
  modules=("${filtered[@]}")
fi

# --- Upfront prompts -----------------------------------------------------
# Ask every optional y/n or choice question here, before the full-screen UI
# takes over the screen and before any module runs. Mid-run prompts would
# either scroll by unseen in the log region or silently block the whole
# install waiting on input nobody's watching for. This only fires when
# running the full, unfiltered install (or a filtered run that specifically
# targets one of these modules).
#
# The category picker (gum, a full interactive TUI) especially cannot run
# once ui_init has carved out its VT100 scroll region below — gum would be
# fighting over the same terminal. So it's pulled out of the normal
# install/[0-9]*.sh loop and sourced here instead; the loop below skips it.
for i in "${!modules[@]}"; do
  if [[ "$(basename "${modules[$i]}" .sh)" == "03-category-picker" ]]; then
    log "Module: 03-category-picker"
    # shellcheck source=/dev/null
    source "${modules[$i]}"
    unset 'modules[i]'
  fi
done
modules=("${modules[@]}")

if [[ -z "$filter" && -r /dev/tty ]]; then
  if [[ -z "${RAT_NVIDIA_DRIVER:-}" ]]; then
    # shellcheck source=lib/nvidia.sh
    source "$RAT_DIR/lib/nvidia.sh"
    if [[ -z "$(current_nvidia_variant)" ]] && detect_gpu_vendors | grep -qx nvidia; then
      RAT_NVIDIA_DRIVER="$(prompt_nvidia_variant)"
      export RAT_NVIDIA_DRIVER
    fi
  fi
fi

ui_init "${#modules[@]}"

step=0
for module in "${modules[@]}"; do
  name="$(basename "$module" .sh)"
  log "Module: $name"
  # shellcheck source=/dev/null
  source "$module"
  step=$((step + 1))
  ui_progress "$step" "$name"
done

# Restore the plain terminal before anything below prints — run_pending_patches
# does its own `clear`, which would otherwise fight the scroll region above.
ui_cleanup

# A fresh, unfiltered install runs every patch that exists, same as if
# `rat update` had been run right after — nothing seeds the tracker to "skip
# these", since a patch may be a real system change (not just a migration for
# pre-existing state) and fresh boxes need it too. See patches/README.md.
[[ -z "$filter" ]] && run_pending_patches

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
