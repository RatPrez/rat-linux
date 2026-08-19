#!/usr/bin/env bash
# Link the `rat` control script onto PATH -- unless the "updater" category
# (packages/categories/updater.toml, id "rat-cli") was deselected, in which
# case the user deliberately opted out of `rat update`/`rat nvidia`
# entirely (install/03-category-picker.sh warns about this before letting
# it happen). Every patch that exists at install time actually runs at the
# end of install.sh (not skipped) — see patches/README.md — so there's no
# tracker to seed here.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

if ! cat_is_selected "updater" "rat-cli" "$CATEGORIES_DIR/updater.toml"; then
  warn "Updater category deselected -- not linking rat CLI. No 'rat update' / 'rat nvidia' on this machine."
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$RAT_DIR/bin/rat" "$HOME/.local/bin/rat"
ok "rat CLI linked -> ~/.local/bin/rat (run: rat help)"
