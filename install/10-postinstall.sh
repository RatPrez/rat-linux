#!/usr/bin/env bash
# Base KDE Plasma settings + default apps. These write user config files, so most
# take effect at the NEXT login (log out/in or reboot).

# Plasma 6 uses kwriteconfig6; fall back to 5 just in case.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kw=kwriteconfig6
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kw=kwriteconfig5
else
  warn "kwriteconfig not found (Plasma not installed?); skipping KDE settings."
  return 0 2>/dev/null || exit 0
fi

# --- Dark mode ----------------------------------------------------------------
log "Theme -> dark (Breeze Dark)"
if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  plasma-apply-lookandfeel -a org.kde.breezedark.desktop >/dev/null 2>&1 \
    || plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 \
    || "$kw" --file kdeglobals --group General --key ColorScheme BreezeDark
else
  "$kw" --file kdeglobals --group General --key ColorScheme BreezeDark
fi

# --- Animation speed (snappy, ~6/7 toward Instant) ----------------------------
# kdeglobals [KDE] AnimationDurationFactor: 1.0 = default, 0 = instant.
log "Animation speed -> snappy (0.25)"
"$kw" --file kdeglobals --group KDE --key AnimationDurationFactor 0.25

# --- Session restore: start with an empty session -----------------------------
log "Login -> empty session"
"$kw" --file ksmserverrc --group General --key loginMode emptySession

# --- Pointer acceleration off (flat libinput profile) -------------------------
log "Pointer acceleration -> off (flat)"
"$kw" --file kcminputrc --group Mouse --key XLbInptAccelProfileFlat true

# --- Australian regional formats (DD/MM/YYYY dates) ---------------------------
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

# --- Sleep / Hibernate off ----------------------------------------------------
log "Sleep + hibernate -> off (masking systemd targets)"
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 \
  || warn "Couldn't mask sleep targets."

# --- Default applications -----------------------------------------------------
log "Default apps -> brave / vlc / elisa / zed"
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
set_default vlc.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo
set_default org.kde.elisa.desktop audio/mpeg audio/flac audio/x-wav audio/mp4 audio/ogg
set_default dev.zed.Zed.desktop text/plain text/x-csrc text/x-chdr application/json text/markdown

ok "KDE base settings applied. Log out/in (or reboot) for everything to take effect."
