#!/usr/bin/env bash
# Base packages + a fresh keyring/sync before anything else.

log "Refreshing package databases"
sudo pacman -Sy --noconfirm

log "Installing base build tooling"
sudo pacman -S --needed --noconfirm base-devel linux-headers git

ok "Preflight complete"
