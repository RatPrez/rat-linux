#!/usr/bin/env bash
# Nvidia + Wayland enablement, done via modprobe.d + mkinitcpio (bootloader
# agnostic) so we don't have to guess at your GRUB/limine/systemd-boot config.
#
# References the Arch wiki "NVIDIA" DRM kernel mode setting section.

# 1. modeset + fbdev via modprobe options (no kernel cmdline editing needed).
log "Writing /etc/modprobe.d/nvidia.conf (modeset + fbdev)"
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF

# 2. Load nvidia modules early from the initramfs.
mkconf=/etc/mkinitcpio.conf
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

# 3. If the kms hook is present it can race with early module loading; leave it,
#    but make sure the initramfs is regenerated so the modules are picked up.
log "Regenerating initramfs (mkinitcpio -P)"
sudo mkinitcpio -P

ok "Nvidia DRM modeset configured"
warn "If you use suspend/resume, consider enabling the nvidia-{suspend,resume,hibernate} services."
