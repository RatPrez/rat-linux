#!/usr/bin/env bash
# Installs whichever gaming packages were selected in the "gaming" category
# (packages/categories/gaming.toml).

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

install_category "gaming" "$CATEGORIES_DIR/gaming.toml"
ok "Gaming packages processed"
