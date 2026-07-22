# rat-linux

Personal, omarchy-style Arch post-install: **Wayland + KDE Plasma + Nvidia**,
my apps, dev toolchains, and sane KDE defaults — from one curl command on a fresh
Arch base.

It runs *on top of* a booted, logged-in Arch system. It does **not** install Arch
itself, the bootloader, or the kernel.

---

## Setup

### 1. Install a minimal Arch base with `archinstall`

Boot the Arch ISO (**UEFI mode**), run `archinstall`, and select:

- **Profile:** `Minimal` — *not* a desktop profile (rat-linux installs Plasma + SDDM).
- **Kernels:** `linux` (leave default).
- **Additional packages:** `linux-headers` *(needed by the Nvidia DKMS driver;
  if you pick `linux-lts`, add `linux-lts-headers` instead)*.
- **Bootloader:** any of `systemd-boot` / `GRUB` / `Limine` (all fine — rat-linux
  never touches it).
- **Network:** `NetworkManager` (or plan to be on **ethernet** at first boot).
- **User account:** create your user and grant it **superuser (sudo)** rights.

Then reboot into the new system and remove the ISO.

### 2. Run rat-linux

Log in as your user at the text console, confirm you're online
(`ping -c1 archlinux.org`), then:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/RatPrez/rat-linux/master/boot.sh)
```

This clones the repo to `~/.local/share/rat-linux` and runs the installer. Expect
sudo prompts and some AUR packages compiling from source. Near the end it asks
`y/N` whether to also install a bare Hyprland session (default no).

### 3. Reboot and log in

```bash
sudo reboot
```

At the SDDM screen pick the **Plasma (Wayland)** session. Log out/in once more if a
few KDE settings haven't taken effect yet.

> Not public yet? Clone it manually instead:
> `git clone https://github.com/RatPrez/rat-linux.git ~/.local/share/rat-linux && ~/.local/share/rat-linux/install.sh`

---

## What you get

**Desktop:** KDE Plasma (Wayland) with SDDM (themed with **Breeze** so the login
screen matches the Plasma lock screen), XWayland, and KDE portals.
**GPU:** proprietary Nvidia (`nvidia-dkms`) with DRM mode setting for Wayland.
**Audio:** PipeWire + WirePlumber, with laptop firmware (`sof-firmware`, UCM).
**Networking:** NetworkManager, Bluetooth.
**Gaming:** Steam, Vulkan (64/32-bit), GameMode, Faugus Launcher.

**Main apps**

| Category   | Apps |
|------------|------|
| Web        | Brave |
| Code / dev | Zed, GitHub Desktop, Kate/KWrite |
| Media      | VLC, Elisa, Audacity, Blender |
| Office      | LibreOffice |
| Files      | Dolphin |
| Utilities  | Spectacle (screenshots) |
| Chat       | Discord |
| Torrent    | qBittorrent |
| VPN        | Proton VPN |

**Dev toolchains** (deliberately outside pacman): Node via **nvm**, Rust via
**rustup**.

**KDE defaults applied** (module `10-postinstall.sh`):

- Dark theme (Breeze Dark)
- Snappy animations (`AnimationDurationFactor = 0.25`)
- Australian regional format — DD/MM/YYYY dates (`en_AU` locale)
- Login starts with an **empty session** (no window restore)
- **Sleep & hibernate disabled** (systemd sleep targets masked)
- Default apps: **Brave** (web), **VLC** (video), **Elisa** (audio), **Zed** (code)

Most of these are user config, so they land at your next login.

---

## Commands

Scripts in `bin/` are installed to `/usr/local/bin` (on PATH everywhere):

- **`install-davinci <zip>`** — build + install DaVinci Resolve from the AUR from a
  Blackmagic installer zip you downloaded (it patches the PKGBUILD's `pkgver` +
  checksum for you, since the AUR package no longer builds out of the box). Use
  `--studio` for Resolve Studio. `install-davinci --help` for details.

- **`install-joplin`** — build + install the Joplin desktop app from the AUR
  (kept on-demand rather than in the default install).

Add your own by dropping an executable script in `bin/` and re-running the
installer.

---

## Hyprland (optional)

Module `08-hyprland.sh` asks `y/N` whether to add a **bare-minimum Hyprland**
session (compositor + portal + polkit agent + Qt Wayland — no dotfiles). KDE
Plasma is untouched either way; if you say yes, both sessions appear in the SDDM
picker. Skip the prompt on unattended runs with `RAT_HYPRLAND=yes` or `=no`.

---

## Customizing

- **Packages:** edit `packages/pacman.txt` (official) or `packages/aur.txt` (AUR).
  One per line; `#` comments and blank lines ignored. Installs are resilient — a
  package that fails is reported and skipped, and the run continues, with a
  summary of failures at the end.
- **A new step:** drop `install/NN-name.sh`. It's sourced with `lib/common.sh`
  already loaded, so `log`/`ok`/`warn`/`die`, `$RAT_DIR`, `pac_install`,
  `aur_install`, and `read_list` are available.
- **Run one module:** `./install.sh 05-nvidia` (substring match). The whole thing
  is idempotent — safe to re-run.

---

## Layout

```
boot.sh              # the only thing you curl — clones repo, runs install.sh
install.sh           # orchestrator: sources install/[0-9]*.sh in order
lib/common.sh        # logging, config, read_list(), pac_install/aur_install
bin/                 # commands installed to /usr/local/bin (e.g. install-davinci)
packages/
  pacman.txt         # official-repo packages
  aur.txt            # AUR packages
  hyprland.txt       # bare-minimum Hyprland (optional module 08)
install/
  00-preflight.sh    # base-devel, refresh dbs
  01-multilib.sh     # enable [multilib]
  02-aur-helper.sh   # install yay
  03-pacman-packages.sh
  04-aur-packages.sh
  05-nvidia.sh       # DRM modeset via modprobe.d + mkinitcpio
  06-dev-tools.sh    # nvm (Node) + rustup (Rust)
  07-services.sh     # NetworkManager, bluetooth, sddm, PipeWire user services
  08-hyprland.sh     # OPTIONAL: prompts y/N for a bare Hyprland session
  09-user-scripts.sh # install bin/ commands to /usr/local/bin
  10-postinstall.sh  # KDE defaults + default apps
```

## Nvidia note

`05-nvidia.sh` enables DRM mode setting the bootloader-agnostic way:
`options nvidia_drm modeset=1 fbdev=1` in `/etc/modprobe.d/nvidia.conf` plus the
nvidia modules in `mkinitcpio.conf`, then regenerates the initramfs. No GRUB /
systemd-boot / Limine cmdline editing required (a backup is left at
`mkinitcpio.conf.rat.bak`).
