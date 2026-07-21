#!/usr/bin/env bash
# Enable the [multilib] repo (Steam, 32-bit Nvidia/Vulkan libs).

if grep -qE '^\s*\[multilib\]' /etc/pacman.conf; then
  ok "multilib already enabled"
else
  log "Enabling [multilib] in /etc/pacman.conf"
  # Uncomment the [multilib] header and the Include line directly under it.
  sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
  ok "multilib enabled"
fi
