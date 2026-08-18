#!/usr/bin/env bash
# Machines set up before GPU auto-detection (install/05-nvidia.sh used to
# unconditionally install nvidia-open-dkms) have no
# ~/.local/state/rat-linux/nvidia-driver file. Seed it from whatever's
# actually installed so `rat update` / `rat nvidia` know the current variant
# instead of re-prompting or thinking nothing is chosen.

state_dir="$HOME/.local/state/rat-linux"
state_file="$state_dir/nvidia-driver"

if [[ -f "$state_file" ]]; then
  ok "Nvidia driver state already recorded ($(cat "$state_file"))"
elif pacman -Qq nvidia-open-dkms >/dev/null 2>&1; then
  mkdir -p "$state_dir"
  echo "open" > "$state_file"
  ok "Recorded existing Nvidia driver as: open"
elif pacman -Qq nvidia-dkms >/dev/null 2>&1; then
  mkdir -p "$state_dir"
  echo "proprietary" > "$state_file"
  ok "Recorded existing Nvidia driver as: proprietary"
else
  ok "No existing Nvidia driver installed — nothing to seed"
fi
