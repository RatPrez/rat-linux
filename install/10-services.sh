#!/usr/bin/env bash
# Enable the system services the desktop needs.

log "Enabling NetworkManager"
sudo systemctl enable --now NetworkManager

log "Enabling Bluetooth"
sudo systemctl enable --now bluetooth

log "Enabling SDDM (display manager) on next boot"
sudo systemctl enable sddm

# The Breeze SDDM theme ships with plasma-workspace but isn't selected by
# default; selecting it makes the login screen match the Plasma lock screen.
log "Theming SDDM login -> Breeze (matches the lock screen)"
sudo install -d /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf >/dev/null <<'EOF'
[Theme]
Current=breeze
EOF

# PipeWire + WirePlumber run as user services (no sudo). Without them KDE
# shows "no audio devices". `--now` only works if a user session is live.
log "Enabling PipeWire audio (user services)"
if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user enable --now pipewire pipewire-pulse wireplumber \
    || warn "Couldn't start audio user services now; they'll come up at next login."
else
  systemctl --user enable pipewire pipewire-pulse wireplumber \
    || warn "Couldn't enable audio user services (no user systemd bus right now)."
  warn "No live user session; audio services enabled for next login."
fi

ok "Services enabled"
