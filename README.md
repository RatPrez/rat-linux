# rat-linux

Personal, Arch post-install: **Wayland + KDE Plasma + Nvidia**, plus my apps and
dev toolchains. One curl command from a fresh Arch base.

This repo does **not** install or configure Arch itself, the bootloader, or the
kernel. It runs on top of a booted, logged-in base system.

---

## Requirements

Before running rat-linux you must already have a **bootable Arch system you can
log into as a normal, sudo-capable user**. Concretely:

| # | Requirement | How to satisfy it |
|---|-------------|-------------------|
| 1 | **UEFI boot** | Boot the Arch ISO in UEFI mode (not legacy/CSM). |
| 2 | **Base system installed** | `base linux linux-firmware` (via `archinstall` or `pacstrap`). |
| 3 | **Matching kernel headers** | `linux-headers` for the stock `linux` kernel. If you chose `linux-lts`, install `linux-lts-headers` instead — DKMS needs headers matching every installed kernel. |
| 4 | **A working bootloader** | GRUB **or** systemd-boot **or** Limine — pick exactly one. rat-linux never touches it (see [Bootloader](#bootloader)). |
| 5 | **`sudo` installed** | `pacman -S sudo` if a minimal base lacks it. |
| 6 | **A normal user in `wheel`, sudo enabled** | Create the user, add to `wheel`, and uncomment `%wheel ALL=(ALL:ALL) ALL` in `visudo`. rat-linux **refuses to run as root**. |
| 7 | **Working internet after reboot** | Easiest on **ethernet** (works out of the box). On Wi-Fi you have no NetworkManager yet, so either install on ethernet or pre-install `networkmanager` and connect before running. |
| 8 | **An Nvidia GPU** | The package list installs the proprietary `nvidia-dkms` stack. Non-Nvidia machines: remove the Nvidia block from `packages/pacman.txt` and skip `05-nvidia.sh` first. |

### Using `archinstall`

If you install with `archinstall`, these settings produce a compatible base:

- **Profile:** `Minimal` — **do not** pick a desktop/greeter profile; rat-linux
  installs Plasma + SDDM itself.
- **Bootloader:** any of `systemd-boot` / `GRUB` / `Limine`.
- **Kernels:** `linux` (default). Add `linux-headers` under "Additional packages",
  or just let rat-linux's preflight install it.
- **Network:** choose `NetworkManager` (or plan to be on ethernet at first boot).
- **User account:** create your user and grant it superuser (sudo) rights.

---

## Install steps

1. **Finish the base Arch install above and reboot** into the new system
   (remove the ISO).

2. **Log in as your normal user** at the TTY (you'll land in a text console —
   there is no desktop yet).

3. **Confirm you're online:**

   ```bash
   ping -c1 archlinux.org
   ```

   If this fails on Wi-Fi, connect first (e.g. `nmcli device wifi connect "SSID" password "…"`
   if NetworkManager is installed, otherwise `iwctl`).

4. **Run the bootstrap:**

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/RatPrez/rat-linux/master/boot.sh)
   ```

   `boot.sh` installs `git`, clones this repo to `~/.local/share/rat-linux`, then
   runs `install.sh`, which executes every `install/` module in numeric order.
   Expect prompts for your sudo password and a long build (DaVinci Resolve and
   other AUR packages compile from source).

5. **Reboot when it finishes:**

   ```bash
   sudo reboot
   ```

6. **At the SDDM login screen, select the `Plasma (Wayland)` session** (session
   picker, usually bottom-left) and log in.

### Running without the curl one-liner

If the repo isn't public yet, clone or copy it onto the machine and run it
directly — same result:

```bash
git clone https://github.com/RatPrez/rat-linux.git ~/.local/share/rat-linux
cd ~/.local/share/rat-linux
./install.sh
```

---

## Bootloader

rat-linux supports **GRUB, systemd-boot, and Limine** equally because it never
edits boot entries or the kernel command line. It enables Nvidia DRM mode setting
purely through `/etc/modprobe.d/nvidia.conf` + `mkinitcpio.conf`, then regenerates
the initramfs.

Quick primer, since it trips people up:

- **systemd-boot** — a minimal **UEFI-only** boot manager that ships as part of
  the systemd project. Not a separate package to reason about beyond `bootctl`.
- **Limine** — an **independent** bootloader (its own project; UEFI *and* BIOS).
  It is **not** part of systemd. If you choose Limine it **replaces**
  systemd-boot/GRUB — you run one bootloader, never two.
- **GRUB** — the traditional, heavier bootloader.

Pick whichever you configured during the Arch install; rat-linux doesn't care.

---

## Layout

```
boot.sh              # the only thing you curl — clones repo, runs install.sh
install.sh           # orchestrator: sources install/[0-9]*.sh in order
lib/common.sh        # logging helpers, config, read_list()
packages/
  pacman.txt         # official-repo packages (edit freely)
  aur.txt            # AUR packages (edit freely)
install/
  00-preflight.sh    # base-devel, refresh dbs
  01-multilib.sh     # enable [multilib]
  02-aur-helper.sh   # install yay
  03-pacman-packages.sh
  04-aur-packages.sh
  05-nvidia.sh       # DRM modeset via modprobe.d + mkinitcpio
  06-dev-tools.sh    # nvm (Node) + rustup (Rust)
  07-services.sh     # NetworkManager, bluetooth, sddm
```

## Usage

```bash
./install.sh              # run everything (idempotent — safe to re-run)
./install.sh 05-nvidia    # run a single module (substring match)
```

## Customizing

- **Add/remove packages:** edit `packages/pacman.txt` or `packages/aur.txt`.
  Lines are `#`-commented and blank-line friendly.
- **Add a step:** drop a new `install/NN-name.sh` file. It's sourced with
  `lib/common.sh` already loaded, so `log`/`ok`/`warn`/`die` and `$RAT_DIR`
  are available.

## Nvidia notes

`05-nvidia.sh` enables DRM kernel mode setting the bootloader-agnostic way:
`options nvidia_drm modeset=1 fbdev=1` in `/etc/modprobe.d/nvidia.conf` plus the
nvidia modules in `mkinitcpio.conf`'s `MODULES`, then regenerates the initramfs.
No GRUB/Limine/systemd-boot cmdline editing required. A backup of
`mkinitcpio.conf` is written to `mkinitcpio.conf.rat.bak`.
