#!/usr/bin/env bash
# Nvidia driver install/switch helpers. Shared by install/05-gpu-drivers.sh
# (first install) and `rat nvidia` (switching later). Sourced with
# lib/common.sh already loaded, so log/ok/warn/die, $RAT_DIR, pac_install,
# and read_list are available.

nvidia_state_file="$HOME/.local/state/rat-linux/nvidia-driver"

# Prints the currently-recorded variant ("open" / "proprietary"), or nothing
# if none has been chosen yet on this machine.
current_nvidia_variant() {
  [[ -f "$nvidia_state_file" ]] && cat "$nvidia_state_file"
  return 0
}

# Package list file for a given variant.
nvidia_pkg_file() {
  case "$1" in
    open)        echo "$RAT_DIR/packages/gpu-nvidia-open.txt" ;;
    proprietary) echo "$RAT_DIR/packages/gpu-nvidia-proprietary.txt" ;;
    *) die "Unknown nvidia variant: $1 (expected 'open' or 'proprietary')" ;;
  esac
}

# Ask (or read $RAT_NVIDIA_DRIVER) which variant to use. Falls back to "open"
# non-interactively — that's Arch's recommended default for Turing/RTX
# 20-series and newer; older cards should set RAT_NVIDIA_DRIVER=proprietary.
prompt_nvidia_variant() {
  local answer="${RAT_NVIDIA_DRIVER:-}"
  if [[ -z "$answer" ]]; then
    if [[ -r /dev/tty ]]; then
      printf 'Nvidia GPU detected. Use (o)pen-source or (p)roprietary kernel modules? [O/p] ' > /dev/tty
      read -r answer < /dev/tty || answer=""
    else
      warn "No TTY to prompt on; defaulting to open-source Nvidia kernel modules. Set RAT_NVIDIA_DRIVER=open|proprietary to force."
      answer="open"
    fi
  fi
  case "${answer,,}" in
    p|proprietary) echo "proprietary" ;;
    *)             echo "open" ;;
  esac
}

# modprobe.d + mkinitcpio DRM modeset wiring (same for either variant).
configure_nvidia_drm() {
  log "Writing /etc/modprobe.d/nvidia.conf (modeset + fbdev)"
  sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF

  local mkconf=/etc/mkinitcpio.conf
  if grep -qE '^MODULES=.*nvidia_drm' "$mkconf"; then
    ok "mkinitcpio MODULES already contains nvidia entries"
  else
    log "Adding nvidia modules to $mkconf"
    sudo cp "$mkconf" "$mkconf.rat.bak"
    # Insert the four modules at the front of the MODULES=(...) array.
    sudo sed -i -E 's/^MODULES=\((.*)\)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm \1)/' "$mkconf"
    # Collapse any doubled spaces left by an empty original array.
    sudo sed -i -E 's/  +/ /g; s/ \)/)/' "$mkconf"
  fi

  log "Regenerating initramfs (mkinitcpio -P)"
  sudo mkinitcpio -P

  ok "Nvidia DRM modeset configured"
  warn "If you use suspend/resume, consider enabling the nvidia-{suspend,resume,hibernate} services."
}

# Install $1 (open|proprietary): removes the other variant's kernel-module
# package if it's installed, installs the chosen one, records the choice,
# and (re)wires up DRM modeset. Idempotent — safe to call with the variant
# already active.
install_nvidia_driver() {
  local variant="$1" other_pkg
  case "$variant" in
    open)        other_pkg="nvidia-dkms" ;;
    proprietary) other_pkg="nvidia-open-dkms" ;;
    *) die "Unknown nvidia variant: $variant (expected 'open' or 'proprietary')" ;;
  esac

  if pacman -Qq "$other_pkg" >/dev/null 2>&1; then
    log "Removing $other_pkg (switching to $variant)"
    sudo pacman -Rns --noconfirm "$other_pkg"
  fi

  log "Installing Nvidia $variant packages"
  pac_install < <(read_list "$(nvidia_pkg_file "$variant")")

  mkdir -p "$(dirname "$nvidia_state_file")"
  echo "$variant" > "$nvidia_state_file"

  configure_nvidia_drm
  ok "Nvidia driver set to: $variant"
}
