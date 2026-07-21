# rat-linux

Personal, Arch post-install: **Wayland + KDE Plasma + Nvidia**,
plus my apps and dev toolchains. One curl command from a fresh Arch base.

## Install

From a freshly-installed Arch system, logged in as your normal (sudo-capable) user:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/RatPrez/rat-linux/main/boot.sh)
```

`boot.sh` installs git, clones this repo to `~/.local/share/rat-linux`, and runs
`install.sh`, which executes every module in `install/` in numeric order.

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
No GRUB/limine/systemd-boot cmdline editing required. A backup of
`mkinitcpio.conf` is written to `mkinitcpio.conf.rat.bak`.
