#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# Arch Linux post-install setup script
# Run as a regular user with sudo privileges (NOT as root).
# ------------------------------------------------------------------

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this as root. Run as your normal user (it'll sudo when needed)."
  exit 1
fi

# ------------------------------------------------------------------
# 1. Enable multilib (needed for Steam, 32-bit Nvidia/Vulkan libs)
# ------------------------------------------------------------------
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo "Enabling multilib repo..."
  sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  # Fallback in case multilib block is fully commented as a pair of lines
  sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
fi

sudo pacman -Sy --noconfirm

# ------------------------------------------------------------------
# 2. Base groups required before anything else
# ------------------------------------------------------------------
BASE_PACKAGES=(
  base-devel
  linux-headers
  git
)

sudo pacman -S --needed --noconfirm "${BASE_PACKAGES[@]}"

# ------------------------------------------------------------------
# 3. Install an AUR helper (yay) if not already present
# ------------------------------------------------------------------
if ! command -v yay &>/dev/null; then
  echo "Installing yay (AUR helper)..."
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# ------------------------------------------------------------------
# 4. Pacman (official repo) packages
# ------------------------------------------------------------------
PACMAN_PACKAGES=(
  # --- Nvidia (proprietary) ---
  nvidia-dkms
  nvidia-utils
  lib32-nvidia-utils
  nvidia-settings
  egl-wayland
  opencl-nvidia

  # --- KDE Plasma (Wayland) ---
  plasma-meta
  sddm
  xorg-xwayland
  xdg-desktop-portal
  xdg-desktop-portal-kde
  bluedevil
  power-profiles-daemon

  # --- Audio ---
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber

  # --- Networking / Bluetooth ---
  networkmanager
  bluez
  bluez-utils

  # --- Gaming / Vulkan ---
  steam
  vulkan-icd-loader
  lib32-vulkan-icd-loader
  gamemode
  lib32-gamemode

  # --- Apps ---
  discord
  audacity
  alacritty
  blender
  brave-browser
  vlc

  # --- Fonts ---
  noto-fonts
  noto-fonts-emoji

  # --- Flatpak ---
  flatpak
)

sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

# ------------------------------------------------------------------
# 5. AUR packages
# ------------------------------------------------------------------
AUR_PACKAGES=(
  xwaylandvideobridge
  davinci-resolve
  protonvpn-gui
  zed
  ttf-jetbrains-mono-nerd
  github-desktop-bin
)

yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

# ------------------------------------------------------------------
# 6. Node via nvm (not pacman nodejs/npm)
# ------------------------------------------------------------------
if [[ ! -d "$HOME/.nvm" ]]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
fi

# ------------------------------------------------------------------
# 7. Rust via rustup (not pacman cargo/rust)
# ------------------------------------------------------------------
if ! command -v rustup &>/dev/null; then
  echo "Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# ------------------------------------------------------------------
# 8. Enable services
# ------------------------------------------------------------------
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable sddm

# ------------------------------------------------------------------
# 9. Nvidia + Wayland kernel params reminder
# ------------------------------------------------------------------
cat <<'EOF'

------------------------------------------------------------------
IMPORTANT MANUAL STEP:
Add the following to your kernel command line (e.g. in
/etc/kernel/cmdline, or your bootloader config) if not already there:

    nvidia-drm.modeset=1 nvidia_drm.fbdev=1

Then regenerate initramfs / bootloader config as appropriate
(e.g. `reinstall-kernels` on limine, or `grub-mkconfig` on GRUB),
and reboot into the Plasma (Wayland) session.
------------------------------------------------------------------

EOF

echo "Done. Reboot when ready."
