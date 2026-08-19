#!/usr/bin/env bash
# UI-only smoke test for install/03-category-picker.sh -- runs the exact
# same gum flow (Quick vs Custom, per-category pickers, Updater-empty
# warning, final summary) with every real pacman/AUR install swapped for a
# harmless "would install X" print, and an isolated $HOME so nothing here
# ever touches your real ~/.local/state/rat-linux/selected-categories.json.
#
# No sudo, no packages touched, no filesystem changes outside a throwaway
# tmp dir that's removed on exit.
#
# Usage: ./test-category-ui.sh
set -euo pipefail

RAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAT_DIR
# shellcheck source=lib/common.sh
source "$RAT_DIR/lib/common.sh"

command -v gum >/dev/null 2>&1 || die "gum isn't installed -- install it first: sudo pacman -S gum"
[[ -r /dev/tty ]] || die "Needs an interactive terminal (a TTY) to test the picker."

# Isolate $HOME so the real selected-categories.json is never touched, and
# clean it up however this script exits (success, error, or Ctrl-C).
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"

# Override pac_install/aur_install with harmless prints. Bash looks up a
# function by name at call time, so these just take over from the real
# ones lib/common.sh defined above once install/03-category-picker.sh
# sources categories.sh and calls them.
pac_install() {
  local pkg
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    printf '  [pacman] would install: %s\n' "$pkg"
  done
}
aur_install() {
  local pkg
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    printf '  [aur]    would install: %s\n' "$pkg"
  done
}

# shellcheck source=install/03-category-picker.sh
source "$RAT_DIR/install/03-category-picker.sh"

echo
ok "UI test complete. Resolved state file (throwaway \$HOME, discarded on exit):"
cat "$CATEGORY_STATE_FILE"
