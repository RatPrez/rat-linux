#!/usr/bin/env bash
# Category-optional theme extras (packages/categories/theme.toml):
#   - tokyonight               TokyoNight color scheme + kwin decoration
#   - whitesur-cursors         WhiteSur cursor theme (AUR package + apply)
#   - sleep-hibernate-disable  mask the systemd sleep/suspend/hibernate targets
# bash-it is in the same category but handled by install/12-bash-it.sh, since
# it isn't a KDE setting.
#
# Must run after install/14-postinstall.sh: applying the Breeze Dark global
# look-and-feel there resets the color scheme, so TokyoNight has to layer on
# top rather than the other way around.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

theme_file="$CATEGORIES_DIR/theme.toml"

# Plasma 6 uses kwriteconfig6; fall back to 5 just in case.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kw=kwriteconfig6
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kw=kwriteconfig5
else
  warn "kwriteconfig not found (Plasma not installed?); skipping theme extras."
  return 0 2>/dev/null || exit 0
fi

# Packages first, so the settings applied below have something to point at.
install_category "theme" "$theme_file"

if cat_is_selected "theme" "tokyonight" "$theme_file"; then
  log "Theme -> TokyoNight color scheme + decoration"
  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme TokyoNight >/dev/null 2>&1 \
      || "$kw" --file kdeglobals --group General --key ColorScheme TokyoNight
  else
    "$kw" --file kdeglobals --group General --key ColorScheme TokyoNight
  fi
  "$kw" --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
  "$kw" --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__TokyoNight
else
  ok "TokyoNight overlay not selected; keeping Breeze Dark as-is."
fi

if cat_is_selected "theme" "whitesur-cursors" "$theme_file"; then
  log "Theme -> WhiteSur cursors"
  if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
    plasma-apply-cursortheme WhiteSur-cursors >/dev/null 2>&1 \
      || "$kw" --file kcminputrc --group Mouse --key cursorTheme WhiteSur-cursors
  else
    "$kw" --file kcminputrc --group Mouse --key cursorTheme WhiteSur-cursors
  fi
else
  ok "WhiteSur cursors not selected; skipping."
fi

if cat_is_selected "theme" "sleep-hibernate-disable" "$theme_file"; then
  log "Sleep + hibernate -> off (masking systemd targets)"
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 \
    || warn "Couldn't mask sleep targets."
else
  ok "Sleep/hibernate masking not selected; leaving system defaults."
fi

ok "Theme extras processed"
