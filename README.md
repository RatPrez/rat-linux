# rat-linux

Personal, omarchy-style Arch post-install: **Wayland + KDE Plasma**, automatic
GPU driver detection (AMD/Intel/Nvidia), my apps, dev toolchains, and sane KDE
defaults — from one curl command on a fresh Arch base.

It runs *on top of* a booted, logged-in Arch system. It does **not** install Arch
itself, the bootloader, or the kernel.

---

## Setup

### 1. Install a minimal Arch base with `archinstall`

Boot the Arch ISO (**UEFI mode**), run `archinstall`, and select:

- **Profile:** `Minimal` — *not* a desktop profile (rat-linux installs Plasma + SDDM).
- **Kernels:** `linux` (leave default).
- **Additional packages:** `linux-headers` *(needed if you have an Nvidia GPU,
  for its DKMS driver; if you pick `linux-lts`, add `linux-lts-headers`
  instead)*.
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
sudo prompts and some AUR packages compiling from source. If it detects an
Nvidia GPU it asks once whether to use the open-source or proprietary kernel
modules (default: open-source). Near the end it asks `y/N` whether to also
install extra dev tools (HeidiSQL, Ghidra — default no).

### 3. Reboot and log in

```bash
sudo reboot
```

At the SDDM screen pick the **Plasma (Wayland)** session. Log out/in once more if a
few KDE settings haven't taken effect yet.

> Not public yet? Clone it manually instead:
> `git clone https://github.com/RatPrez/rat-linux.git ~/.local/share/rat-linux && ~/.local/share/rat-linux/install.sh`

### 4. Keeping it up to date

`install.sh` links a `rat` command onto your `PATH`. On any machine that's
already been set up, run:

```bash
rat update
```

This pulls the latest commits, re-runs the install steps (new packages get
installed, dotfile symlinks get refreshed), applies any pending `patches/`,
then upgrades the system (`pacman -Syu`, `yay -Syu`, `flatpak update`).
`rat help` lists everything else.

---

## What you get

**Desktop:** KDE Plasma (Wayland) with SDDM (themed with **Breeze** so the login
screen matches the Plasma lock screen), XWayland, and KDE portals.
**GPU:** auto-detected driver stack — AMD (mesa RADV), Intel (mesa ANV), or
Nvidia (open or proprietary DKMS modules, your choice, with DRM mode setting
for Wayland). Hybrid (Intel+Nvidia) laptops get both stacks.
**Audio:** PipeWire + WirePlumber, with laptop firmware (`sof-firmware`, UCM).
**Networking:** NetworkManager, Bluetooth.
**Gaming:** Steam, Vulkan (64/32-bit), GameMode, Faugus Launcher.

**Main apps**

| Category   | Apps |
|------------|------|
| Web        | Brave |
| Code / dev | Zed, GitHub Desktop, Kate/KWrite |
| Media      | MPV, Elisa, Blender, OBS Studio |
| Office     | LibreOffice |
| Files      | Dolphin |
| Utilities  | Spectacle (screenshots), GNOME Disks, btop, fastfetch, AppImageLauncher |
| Chat       | Discord |
| Torrent    | qBittorrent |
| VPN        | Proton VPN |

**Dev toolchains** (deliberately outside pacman): Node via **nvm**, Rust via
**rustup**.

**Shell:** bash-it, themed **Tokyo Dark** (matches the Plasma/Alacritty Tokyo
Night theme above).

**KDE defaults applied** (module `11-postinstall.sh`):

- Dark theme (Breeze Dark), then **TokyoNight** color scheme + window decoration
  (bundled as dotfiles under `home/`) and **WhiteSur** cursors on top
- Snappy animations (`AnimationDurationFactor = 0.25`)
- Australian regional format — DD/MM/YYYY dates (`en_AU` locale)
- Login starts with an **empty session** (no window restore)
- **Sleep & hibernate disabled** (systemd sleep targets masked)
- Default apps: **Brave** (web), **MPV** (video), **Elisa** (audio), **Zed** (code)

Most of these are user config, so they land at your next login.

---

## Customizing

- **Packages:** edit `packages/pacman.txt` (official), `packages/aur.txt` (AUR),
  or `packages/flatpak.txt` (Flatpak). One per line; `#` comments and blank lines
  ignored. Installs are resilient — a package that fails is reported and
  skipped, and the run continues, with a summary of failures at the end.
  GPU packages live separately in `packages/gpu-{amd,intel}.txt` and
  `packages/gpu-nvidia-{open,proprietary}.txt` — see the GPU section below.
- **Dotfiles:** drop files under `home/`, mirroring their real location in `$HOME`
  (`home/.config/foo/bar` → `~/.config/foo/bar`). Module `10-dotfiles.sh`
  **symlinks** them into place — config is always read live from `$RAT_DIR`, so
  editing a file here (or `rat update` pulling new commits) applies immediately.
  A real (non-symlink) file already at the destination is backed up once to
  `<file>.rat.bak-<timestamp>` before being replaced.
- **A new step:** drop `install/NN-name.sh`. It's sourced with `lib/common.sh`
  already loaded, so `log`/`ok`/`warn`/`die`, `$RAT_DIR`, `pac_install`,
  `aur_install`, and `read_list` are available.
- **Run one module:** `./install.sh 05-gpu` (substring match). The whole thing
  is idempotent — safe to re-run.
- **A one-off migration for machines that already have rat-linux installed:**
  drop `patches/NNNN-name.sh` (see `patches/README.md`). `rat update` runs any
  patch newer than the machine's tracked level, oldest first.

---

## Layout

```
boot.sh              # the only thing you curl — clones repo, runs install.sh
install.sh           # orchestrator: sources install/[0-9]*.sh in order, primes sudo
bin/rat              # control script once installed: `rat update`, `rat nvidia`, `rat help`
lib/common.sh        # logging, config, read_list(), pac_install/aur_install, detect_gpu_vendors()
lib/nvidia.sh        # nvidia variant prompt/install/switch, shared by 05-gpu-drivers.sh + `rat nvidia`
packages/
  pacman.txt         # official-repo packages (GPU-agnostic)
  aur.txt            # AUR packages
  flatpak.txt        # Flatpak apps
  gpu-amd.txt         # AMD mesa/Vulkan stack
  gpu-intel.txt       # Intel mesa/Vulkan stack
  gpu-nvidia-open.txt        # Nvidia open-source (nvidia-open-dkms) stack
  gpu-nvidia-proprietary.txt # Nvidia proprietary (nvidia-dkms) stack
  extra-dev-tools.txt # OPTIONAL: prompted, see module 13 below
install/
  00-preflight.sh    # base-devel, pciutils, refresh dbs
  01-multilib.sh     # enable [multilib]
  02-aur-helper.sh   # install yay
  03-pacman-packages.sh
  04-aur-packages.sh
  05-gpu-drivers.sh  # detect AMD/Intel/Nvidia, install matching driver(s)
  06-dev-tools.sh    # nvm (Node) + rustup (Rust)
  07-services.sh     # NetworkManager, bluetooth, sddm, PipeWire user services
  08-flatpak.sh      # Flatpak apps (adds Flathub remote)
  09-bash-it.sh      # clones the bash-it framework (drives the prompt/theme)
  10-dotfiles.sh     # symlink home/ into $HOME (backs up anything it replaces)
  11-postinstall.sh  # KDE defaults + default apps, font cache, keyring reset
  12-rat-cli.sh      # links bin/rat onto PATH, seeds the patch tracker
  13-extra-dev-tools.sh # OPTIONAL: prompts y/N for HeidiSQL + Ghidra
patches/             # one-off migrations for existing installs, run by `rat update`
home/                # dotfiles symlinked into $HOME (home/.config/... -> ~/.config/...)
```

## GPU driver detection

`05-gpu-drivers.sh` runs `lspci` (via `detect_gpu_vendors()` in `lib/common.sh`)
to see which of AMD / Intel / Nvidia are actually present, and only installs
the matching driver stack(s) — a hybrid Intel+Nvidia laptop gets both.

For Nvidia, it also asks once whether to use the **open-source**
(`nvidia-open-dkms`, the default — Turing/RTX 20-series and newer) or
**proprietary** (`nvidia-dkms`, needed for older cards) kernel modules. The
choice is remembered at `~/.local/state/rat-linux/nvidia-driver`, so re-runs
(`rat update`) don't ask again; set `RAT_NVIDIA_DRIVER=open` or `=proprietary`
to skip the prompt outright. Change your mind later with:

```bash
rat nvidia
```

Either way, DRM mode setting is enabled the bootloader-agnostic way:
`options nvidia_drm modeset=1 fbdev=1` in `/etc/modprobe.d/nvidia.conf` plus the
nvidia modules in `mkinitcpio.conf`, then the initramfs is regenerated. No GRUB /
systemd-boot / Limine cmdline editing required (a backup is left at
`mkinitcpio.conf.rat.bak`).
