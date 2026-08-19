#!/usr/bin/env bash
# Enable the system services the desktop needs.

log "Enabling NetworkManager"
sudo systemctl enable --now NetworkManager

log "Enabling Bluetooth"
sudo systemctl enable --now bluetooth

log "Enabling SDDM (display manager) on next boot"
sudo systemctl enable sddm

# Use the KDE "Breeze" SDDM theme so the login screen matches the Plasma lock
# screen (both then use the Breeze look). The theme ships with plasma-workspace;
# it just isn't selected by default. Fine-tune wallpaper/avatar later in
# System Settings > Colors & Themes > Login Screen (SDDM).
log "Theming SDDM login -> Breeze (matches the lock screen)"
sudo install -d /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf >/dev/null <<'EOF'
[Theme]
Current=breeze
EOF

# PipeWire + WirePlumber run as *user* services (no sudo). Without these enabled,
# no sound server runs and KDE shows "no audio devices". `enable` sets them up for
# every future login; `--now` tries to start them immediately if a user session is
# live (harmless best-effort otherwise).
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
