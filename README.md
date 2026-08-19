# rat-linux

Personal, omarchy-style Arch post-install: **Wayland + KDE Plasma**, automatic
GPU driver detection (AMD/Intel/Nvidia), my apps, dev toolchains, and sane KDE
defaults, from one curl command on a fresh Arch base.

It runs *on top of* a booted, logged-in Arch system. It does **not** install Arch
itself, the bootloader, or the kernel.

---

## Setup

### 1. Install a minimal Arch base with `archinstall`

Boot the Arch ISO (**UEFI mode**), run `archinstall`, and select:

- **Profile:** `Minimal`, *not* a desktop profile (rat-linux installs Plasma + SDDM).
- **Kernels:** `linux` (leave default).
- **Additional packages:** `linux-headers` *(needed if you have an Nvidia GPU,
  for its DKMS driver; if you pick `linux-lts`, add `linux-lts-headers`
  instead)*.
- **Bootloader:** any of `systemd-boot` / `GRUB` / `Limine` (all fine, since
  rat-linux never touches it).
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
sudo prompts and some AUR packages compiling from source. Early on it asks
**Quick install** (accept every category's defaults, no further input) or
**Custom install** (walk Dev tools → Browsers → Gaming → Updater → Theme,
one `gum` picker per category, defaults pre-selected; see
[Categories](#categories) below). If it detects an Nvidia GPU it separately
asks once whether to use the open-source or proprietary kernel modules
(default: open-source).

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
**GPU:** auto-detected driver stack: AMD (mesa RADV), Intel (mesa ANV), or
Nvidia (open or proprietary DKMS modules, your choice, with DRM mode setting
for Wayland). Hybrid (Intel+Nvidia) laptops get both stacks.
**Audio:** PipeWire + WirePlumber, with laptop firmware (`sof-firmware`, UCM).
**Networking:** NetworkManager, Bluetooth.

These, plus base apps (Alacritty, Dolphin, LibreOffice, Spectacle, qBittorrent,
Proton VPN, Vesktop, ...) and the base **Breeze Dark** KDE look, install
unconditionally; see [Categories](#categories) below for everything that's
optional (browsers, gaming, dev tools, the `rat` CLI, and the TokyoNight/
WhiteSur/bash-it theme layer).

**KDE defaults always applied** (module `14-postinstall.sh`):

- Dark theme (**Breeze Dark**)
- Snappy animations (`AnimationDurationFactor = 0.25`)
- Australian regional format, DD/MM/YYYY dates (`en_AU` locale)
- Login starts with an **empty session** (no window restore)
- Default apps set for whichever of Brave / MPV / Elisa / Zed you selected

Most of these are user config, so they land at your next login.

---

## Categories

Early in the install, `03-category-picker.sh` (via `gum`) asks **Quick
install** (accept every category's defaults, no further input) or **Custom
install** (walk each category, toggle items with tab/space, confirm with
enter). The five categories, each in `packages/categories/<name>.toml`:

| Category | Examples | Notes |
|----------|----------|-------|
| Dev tools | Zed, GitHub Desktop, nvm/rustup, HeidiSQL, Ghidra, `gh` | HeidiSQL/Ghidra/`gh` default off |
| Browsers | Brave, Firefox, Chromium, LibreWolf | multi-select |
| Gaming | Steam, Vulkan, GameMode, Wine, Faugus Launcher | |
| Updater | the `rat` CLI itself; whether `rat update` also runs `flatpak update`; whether `rat nvidia` is available | can be entirely deselected, and you're warned first |
| Theme | TokyoNight color scheme + decoration, WhiteSur cursors, bash-it (Tokyo Dark prompt), sleep/hibernate disable | layered on top of the core Breeze Dark base |

Selections are saved to `~/.local/state/rat-linux/selected-categories.json`
(`"category.id": true/false`). Category-consuming modules
(`07-browsers.sh`, `08-dev-tools.sh`, `09-gaming.sh`, `12-bash-it.sh`,
`15-theme.sh`, `16-rat-cli.sh`) read it via `lib/categories.sh`; if it's
missing (e.g. running one of those modules standalone before ever running
the picker) they fall back to each manifest's own `default = true` items.
Re-running the picker (`./install.sh 03-category-picker`, or a fresh
`rat update`-driven `install.sh` run) reopens it pre-seeded from your last
selection, so revisiting is just re-picking, not replaying blindly.

Add a new pickable item by adding an `[[item]]` block to the relevant
`packages/categories/*.toml` (see `lib/categories.sh` for the format:
`id`/`name`/`source` [`pacman`|`aur`|`flatpak`|`script`|`toggle`|`custom`]/
`package`/`default`/`description`). `pacman`/`aur`/`flatpak` items install
automatically; a `script` item needs a matching `cat_script_<id>` (or
whatever prefix the calling module uses) function defined before
`install_category` is called; `toggle`/`custom` items are read live by
whatever consumes them (`bin/rat`, `install/15-theme.sh`) instead of being
installed.

---

## Customizing

- **Packages:** edit `packages/pacman.txt` (official), `packages/aur.txt` (AUR),
  or `packages/flatpak.txt` (Flatpak) for anything that should install
  unconditionally. One per line; `#` comments and blank lines ignored.
  Installs are resilient: a package that fails is reported and skipped, and
  the run continues, with a summary of failures at the end. GPU packages live
  separately in `packages/gpu-{amd,intel}.txt` and
  `packages/gpu-nvidia-{open,proprietary}.txt`; see the GPU section below.
  Anything that should be user-optional belongs in
  `packages/categories/*.toml` instead; see [Categories](#categories).
- **Dotfiles:** drop files under `home/`, mirroring their real location in `$HOME`
  (`home/.config/foo/bar` → `~/.config/foo/bar`). Module `13-dotfiles.sh`
  **symlinks** them into place, so config is always read live from `$RAT_DIR` and
  editing a file here (or `rat update` pulling new commits) applies immediately.
  A real (non-symlink) file already at the destination is backed up once to
  `<file>.rat.bak-<timestamp>` before being replaced.
- **A new step:** drop `install/NN-name.sh`. It's sourced with `lib/common.sh`
  already loaded, so `log`/`ok`/`warn`/`die`, `$RAT_DIR`, `pac_install`,
  `aur_install`, and `read_list` are available.
- **Run one module:** `./install.sh 06-gpu` (substring match). The whole thing
  is idempotent and safe to re-run.
- **A one-off migration for machines that already have rat-linux installed:**
  drop `patches/NNNN-name.sh` (see `patches/README.md`). `rat update` runs any
  patch newer than the machine's tracked level, oldest first.

---

## Layout

```
boot.sh              # the only thing you curl: clones repo, runs install.sh
install.sh           # orchestrator: sources install/[0-9]*.sh in order, primes sudo
bin/rat              # control script once installed: `rat update`, `rat nvidia`, `rat help`
lib/common.sh        # logging, config, read_list(), pac_install/aur_install, detect_gpu_vendors()
lib/nvidia.sh        # nvidia variant prompt/install/switch, shared by 06-gpu-drivers.sh + `rat nvidia`
lib/categories.sh    # category manifest parsing, selection state, install_category() engine
packages/
  pacman.txt         # official-repo packages (unconditional)
  aur.txt            # AUR packages (unconditional)
  flatpak.txt        # Flatpak apps (unconditional)
  gpu-amd.txt         # AMD mesa/Vulkan stack
  gpu-intel.txt       # Intel mesa/Vulkan stack
  gpu-nvidia-open.txt        # Nvidia open-source (nvidia-open-dkms) stack
  gpu-nvidia-proprietary.txt # Nvidia proprietary (nvidia-dkms) stack
  categories/        # OPTIONAL, user-picked: dev-tools/browsers/gaming/updater/theme.toml
install/
  00-preflight.sh    # base-devel, pciutils, refresh dbs
  01-multilib.sh     # enable [multilib]
  02-aur-helper.sh   # install yay
  03-category-picker.sh # Quick/Custom install picker (gum), writes selected-categories.json
  04-pacman-packages.sh
  05-aur-packages.sh
  06-gpu-drivers.sh  # detect AMD/Intel/Nvidia, install matching driver(s)
  07-browsers.sh     # OPTIONAL: browsers category
  08-dev-tools.sh    # OPTIONAL: dev-tools category (incl. nvm/rustup)
  09-gaming.sh       # OPTIONAL: gaming category
  10-services.sh     # NetworkManager, bluetooth, sddm, PipeWire user services
  11-flatpak.sh      # Flatpak apps (adds Flathub remote)
  12-bash-it.sh      # OPTIONAL (theme category): clones the bash-it framework
  13-dotfiles.sh     # symlink home/ into $HOME (backs up anything it replaces)
  14-postinstall.sh  # CORE KDE defaults + default apps, font cache, keyring reset
  15-theme.sh        # OPTIONAL: theme category (TokyoNight, WhiteSur, sleep/hibernate mask)
  16-rat-cli.sh      # OPTIONAL (updater category): links bin/rat onto PATH
patches/             # one-off migrations for existing installs, run by `rat update`
home/                # dotfiles symlinked into $HOME (home/.config/... -> ~/.config/...)
```

## GPU driver detection

`06-gpu-drivers.sh` runs `lspci` (via `detect_gpu_vendors()` in `lib/common.sh`)
to see which of AMD / Intel / Nvidia are actually present, and only installs
the matching driver stack(s). A hybrid Intel+Nvidia laptop gets both.

For Nvidia, it also asks once whether to use the **open-source**
(`nvidia-open-dkms`, the default for Turing/RTX 20-series and newer) or
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
