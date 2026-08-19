#!/usr/bin/env bash
# Installs whatever was selected in the "apps" category
# (packages/categories/apps.toml): optional VPN clients and office suite.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

apps_file="$CATEGORIES_DIR/apps.toml"

install_category "apps" "$apps_file"

# The NymVPN GUI talks to nym-vpnd over a socket and cannot connect without
# it. The daemon comes in as a dependency of nym-vpn-app, but nothing starts
# it, so an unenabled daemon looks like a broken app.
if cat_is_selected "apps" "nymvpn" "$apps_file"; then
  if systemctl cat nym-vpnd.service >/dev/null 2>&1; then
    log "Enabling nym-vpnd (NymVPN daemon)"
    sudo systemctl enable --now nym-vpnd \
      || warn "Couldn't enable nym-vpnd; start it before using NymVPN."
  else
    warn "nym-vpnd.service not found; NymVPN won't connect until its daemon runs."
  fi
fi

ok "Extra apps processed"
