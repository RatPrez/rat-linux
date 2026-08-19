#!/usr/bin/env bash
# Base KDE Plasma settings + default apps. These write user config files, so
# most take effect at the next login.
#
# This is the core look rat-linux always applies. The optional theme layer
# lives in install/15-theme.sh, which must run after this module: applying a
# global look-and-feel here resets the color scheme.

# Plasma 6 uses kwriteconfig6; fall back to 5 just in case.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kw=kwriteconfig6
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kw=kwriteconfig5
else
  warn "kwriteconfig not found (Plasma not installed?); skipping KDE settings."
  return 0 2>/dev/null || exit 0
fi

log "Theme -> dark (Breeze Dark)"
if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  plasma-apply-lookandfeel -a org.kde.breezedark.desktop >/dev/null 2>&1 \
    || plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 \
    || "$kw" --file kdeglobals --group General --key ColorScheme BreezeDark
else
  "$kw" --file kdeglobals --group General --key ColorScheme BreezeDark
fi

# AnimationDurationFactor: 1.0 = default, 0 = instant.
log "Animation speed -> snappy (0.25)"
"$kw" --file kdeglobals --group KDE --key AnimationDurationFactor 0.25

log "Login -> empty session"
"$kw" --file ksmserverrc --group General --key loginMode emptySession

log "Regional format -> en_AU (DD/MM/YYYY)"
if ! locale -a 2>/dev/null | grep -qiE '^en_AU\.utf-?8$'; then
  if grep -qE '^#?en_AU\.UTF-8 UTF-8' /etc/locale.gen; then
    sudo sed -i 's/^#\?en_AU\.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen
  else
    echo 'en_AU.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
  fi
  sudo locale-gen
fi
"$kw" --file plasma-localerc --group Formats --key LANG en_AU.UTF-8

log "Default apps -> brave / mpv / elisa / zed"
set_default() {  # $1 = desktop id, rest = mimetypes
  local desk="$1"; shift
  if ! find /usr/share/applications "$HOME/.local/share/applications" \
        -name "$desk" 2>/dev/null | grep -q .; then
    warn "default-app skipped: $desk not installed"
    return
  fi
  xdg-mime default "$desk" "$@" 2>/dev/null || warn "xdg-mime failed for $desk"
}

xdg-settings set default-web-browser brave-browser.desktop 2>/dev/null || true
set_default brave-browser.desktop x-scheme-handler/http x-scheme-handler/https text/html
set_default mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo
set_default org.kde.elisa.desktop audio/mpeg audio/flac audio/x-wav audio/mp4 audio/ogg
set_default dev.zed.Zed.desktop text/plain text/x-csrc text/x-chdr application/json text/markdown

ok "KDE base settings applied. Log out/in (or reboot) for everything to take effect."

# Rebuild the fontconfig cache so the fonts installed above are picked up
# without needing a reboot first.
log "Rebuilding font cache (fc-cache -fv)"
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -fv >/dev/null 2>&1 || warn "fc-cache reported an error; fonts may need a reboot."
  ok "Font cache rebuilt"
else
  warn "fc-cache not found; skipping font cache rebuild."
fi

# On a fresh install the gnome-keyring "login" keyring can be missing or
# stale, leaving ProtonVPN unable to store its session. Clearing the keyring
# files makes gnome-keyring regenerate one at the next login, when PAM unlocks
# it with your password. Safe here because a fresh install has no secrets.
keyring_dir="$HOME/.local/share/keyrings"
if [[ -d "$keyring_dir" ]] && compgen -G "$keyring_dir/*.keyring" >/dev/null; then
  log "Resetting gnome-keyring so ProtonVPN can regenerate it"
  ts="$(date +%Y%m%d%H%M%S)"
  mkdir -p "$keyring_dir/rat-backup-$ts"
  mv "$keyring_dir"/*.keyring "$keyring_dir/rat-backup-$ts"/ 2>/dev/null || true
  rm -f "$keyring_dir/default" 2>/dev/null || true
  ok "Keyring reset (old files backed up to $keyring_dir/rat-backup-$ts); it regenerates at next login."
else
  log "No existing keyring found; gnome-keyring will generate one on first login."
fi
