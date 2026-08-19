#!/usr/bin/env bash
# Nvidia driver install helpers, used by install/06-gpu-drivers.sh.

# modprobe.d + mkinitcpio DRM modeset wiring.
configure_nvidia_drm() {
  log "Writing /etc/modprobe.d/nvidia.conf (modeset + fbdev)"
  sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'CONF'
options nvidia_drm modeset=1 fbdev=1
CONF

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
  sudo mkinitcpio -P || warn "mkinitcpio failed; rerun it before rebooting."

  ok "Nvidia DRM modeset configured"
  warn "If you use suspend/resume, consider enabling the nvidia-{suspend,resume,hibernate} services."
}

# Install the Nvidia stack and wire up DRM modeset. Idempotent.
install_nvidia_driver() {
  log "Installing Nvidia packages"
  pac_install < <(read_list "$RAT_DIR/packages/gpu-nvidia.txt")
  configure_nvidia_drm
  ok "Nvidia driver installed"
}
