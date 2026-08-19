#!/usr/bin/env bash
# UI-only smoke test for install/03-category-picker.sh: runs the same gum
# flow with every real pacman/AUR install swapped for a "would install X"
# print, and an isolated $HOME so it never touches your real
# ~/.local/state/rat-linux/selected-categories.json.
#
# No sudo, no packages touched, no filesystem changes outside a throwaway tmp
# dir that's removed on exit.
#
# Usage: ./test-category-ui.sh
set -euo pipefail

RAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAT_DIR
# shellcheck source=lib/common.sh
source "$RAT_DIR/lib/common.sh"

command -v gum >/dev/null 2>&1 || die "gum isn't installed. Install it first: sudo pacman -S gum"
have_tty || die "Needs an interactive terminal (a TTY) to test the picker."

# Isolated $HOME, removed however this script exits.
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"

# Bash resolves function names at call time, so these take over from the real
# pac_install/aur_install that lib/common.sh defined above.
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
