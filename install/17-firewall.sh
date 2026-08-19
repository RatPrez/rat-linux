#!/usr/bin/env bash
# Host firewall: ufw, defaulting to deny-incoming / allow-outgoing.
#
# ufw is installed here rather than from packages/pacman.txt so that
# patches/0003-enable-ufw.sh can source this module and set an existing
# machine up in one go; `rat update` upgrades packages but never installs new
# entries from the package lists.
#
# Inbound rules are opened only for the things this install actually uses:
# KDE Connect (part of plasma-meta), Steam's in-home streaming if the gaming
# category was selected, and SSH if an sshd is already running, so applying
# this over an SSH session can't cut the connection.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

pac_install <<<"ufw"

if ! command -v ufw >/dev/null 2>&1; then
  warn "ufw not installed; skipping firewall setup."
  return 0 2>/dev/null || exit 0
fi

# Rules first, then enable, so the box is never up with an empty policy.
log "Firewall defaults -> deny incoming, allow outgoing"
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null

if systemctl is-active --quiet sshd; then
  log "Firewall -> allowing SSH (sshd is running)"
  sudo ufw allow OpenSSH >/dev/null
fi

log "Firewall -> allowing KDE Connect (1714-1764)"
sudo ufw allow 1714:1764/tcp >/dev/null
sudo ufw allow 1714:1764/udp >/dev/null

if cat_is_selected "gaming" "steam" "$CATEGORIES_DIR/gaming.toml"; then
  log "Firewall -> allowing Steam in-home streaming"
  sudo ufw allow 27031:27036/udp >/dev/null
  sudo ufw allow 27036:27037/tcp >/dev/null
fi

sudo ufw --force enable
sudo systemctl enable ufw >/dev/null 2>&1 || warn "Couldn't enable ufw.service for next boot."

ok "Firewall enabled. Review it with: sudo ufw status verbose"
