#!/usr/bin/env bash
# Link the `rat` control script onto PATH, unless the "updater" category was
# deselected, in which case the user opted out of `rat update` entirely (the
# picker warns before letting that happen).

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

if ! cat_is_selected "updater" "rat-cli" "$CATEGORIES_DIR/updater.toml"; then
  warn "Updater category deselected; not linking the rat CLI. No 'rat update' on this machine."
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$RAT_DIR/bin/rat" "$HOME/.local/bin/rat"
ok "rat CLI linked -> ~/.local/bin/rat (run: rat help)"
