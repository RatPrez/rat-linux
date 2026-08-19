#!/usr/bin/env bash
# Installs whichever browsers were selected in the "browsers" category
# (packages/categories/browsers.toml). More than one may be selected.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

install_category "browsers" "$CATEGORIES_DIR/browsers.toml"
ok "Browsers processed"
