#!/usr/bin/env bash
# Enable the system services the desktop needs.

log "Enabling NetworkManager"
sudo systemctl enable --now NetworkManager

log "Enabling Bluetooth"
sudo systemctl enable --now bluetooth

log "Enabling SDDM (display manager) on next boot"
sudo systemctl enable sddm

ok "Services enabled"
