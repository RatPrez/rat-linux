# rat-linux

Personal Arch post-install script: KDE Plasma on Wayland, auto-detected GPU
drivers, my apps, dotfiles and KDE defaults, in one command.

It runs *on top of* a booted, logged-in Arch system. It does not install Arch,
the bootloader, or the kernel.

## Running it

Install a minimal Arch base with `archinstall` (profile `Minimal`, and add
`linux-headers` if you have an Nvidia GPU). Reboot, log in, confirm you're
online, then:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/RatPrez/rat-linux/master/boot.sh)
```

It asks Quick or Custom install up front, then runs unattended. Reboot into the
Plasma (Wayland) session when it finishes.

Afterwards, `rat update` pulls the latest commits, upgrades the system, and
applies any new patches. `rat help` lists the rest.

To run a single module: `./install.sh 06-gpu`.

## Warning

**Read the source before you run it.** It installs packages, enables system
services, masks systemd targets, and overwrites desktop and system
configuration. Some of that is not trivially reversible.

Provided **AS IS**, without warranty of any kind, express or implied, and
without support. It is built for my hardware and my preferences. You run it
entirely at your own risk.

MIT licensed, see [LICENSE](LICENSE).
