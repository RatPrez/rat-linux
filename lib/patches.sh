#!/usr/bin/env bash
# Shared "run pending patches" machinery, used by both install.sh (a fresh
# box runs every patch that exists, same as if it had done `rat update` right
# after installing) and `bin/rat update` (an existing box runs whatever's new
# since its last run). Same state file either way, so patches never replay
# and never get silently skipped. See patches/README.md.
#
# Sourced with lib/common.sh already loaded, so log/ok/warn/die and $RAT_DIR
# are available.

state_dir="$HOME/.local/state/rat-linux"
level_file="$state_dir/patch-level"

current_patch_level() {
  [[ -f "$level_file" ]] && cat "$level_file" || echo 0
}

# Prints a patch's "# CHANGELOG: ..." comment lines, one bullet per line.
# Read with grep/sed, not by executing the patch — so this works before (and
# without) actually running it.
print_patch_changelog() {
  local p="$1" line
  while IFS= read -r line; do
    printf '     - %s\n' "$line"
  done < <(grep '^# CHANGELOG: ' "$p" | sed 's/^# CHANGELOG: //')
}

# Run every patches/NNNN-*.sh newer than the tracked level, oldest first.
# Stops at the first failure so nothing after a broken patch is applied.
run_pending_patches() {
  mkdir -p "$state_dir"
  local current
  current="$(current_patch_level)"

  shopt -s nullglob
  local all_patches=("$RAT_DIR"/patches/[0-9][0-9][0-9][0-9]-*.sh)
  shopt -u nullglob

  local p base num
  local pending=()
  for p in "${all_patches[@]}"; do
    base="$(basename "$p")"
    num=$((10#${base%%-*}))
    (( num > current )) && pending+=("$p")
  done

  if [[ ${#pending[@]} -eq 0 ]]; then
    ok "No pending patches"
    return
  fi

  # Clear whatever was scrolling before (package upgrades, module output) so
  # the patch list is the first thing visible, not buried under it.
  clear
  log "Applying ${#pending[@]} pending patch(es)"

  for p in "${pending[@]}"; do
    base="$(basename "$p")"
    num=$((10#${base%%-*}))

    log "Patch $base"
    print_patch_changelog "$p"

    if ( set -euo pipefail; source "$RAT_DIR/lib/common.sh"; source "$p" ); then
      echo "$num" > "$level_file"
      ok "Patch $base applied"
    else
      die "Patch $base failed — fix it and re-run 'rat update'. Nothing after it will run until it does."
    fi
  done

  ok "${#pending[@]} patch(es) applied"
}
