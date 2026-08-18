#!/usr/bin/env bash
# Shared helpers + config. Sourced by install.sh and every install/*.sh module.

# --- Repo location (used by boot.sh to clone) ---------------------------------
: "${RAT_REPO:=https://github.com/RatPrez/rat-linux.git}"
: "${RAT_BRANCH:=master}"
: "${RAT_DIR:=$HOME/.local/share/rat-linux}"

# --- Logging ------------------------------------------------------------------
_c_reset=$'\033[0m'; _c_blue=$'\033[1;34m'; _c_green=$'\033[1;32m'
_c_yellow=$'\033[1;33m'; _c_red=$'\033[1;31m'

log()  { printf '%s==>%s %s\n' "$_c_blue"   "$_c_reset" "$*"; }
ok()   { printf '%s ok%s %s\n'  "$_c_green"  "$_c_reset" "$*"; }
warn() { printf '%s!!%s %s\n'   "$_c_yellow" "$_c_reset" "$*" >&2; }
die()  { printf '%serr%s %s\n'  "$_c_red"    "$_c_reset" "$*" >&2; exit 1; }

# --- Guards -------------------------------------------------------------------
require_not_root() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run as your normal user (it'll sudo when needed), not root."
}

# Read a package list file: strips comments (#...) and blank lines.
# Usage: mapfile -t pkgs < <(read_list packages/pacman.txt)
read_list() {
  local f="$1"
  [[ -f "$f" ]] || die "Package list not found: $f"
  sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$f"
}

# --- Resilient package installs ----------------------------------------------
# Packages are installed one at a time so a single failure (missing package,
# broken AUR build, network hiccup) is reported and skipped instead of aborting
# the whole run. Failures accumulate in RAT_FAILED_PKGS and are summarized by
# install.sh at the end.
RAT_FAILED_PKGS=()

# Internal: run installer "$1 ..." for each remaining package, recording failures.
_install_each() {
  local label="$1"; shift
  local installer=("$@")   # installer command WITHOUT the package name
  local pkg
  # The package list arrives on stdin (one per line) to keep quoting simple.
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    if "${installer[@]}" "$pkg"; then
      ok "$label: $pkg"
    else
      warn "$label FAILED: $pkg  (skipping, continuing with the rest)"
      RAT_FAILED_PKGS+=("$pkg")
    fi
  done
}

# Install official-repo packages via pacman, one at a time.
pac_install() { _install_each "pacman" sudo pacman -S --needed --noconfirm; }

# Install AUR packages via yay, one at a time.
aur_install() { _install_each "aur" yay -S --needed --noconfirm; }

# --- Sudo credential keepalive -------------------------------------------
# Prompts for the sudo password once, then refreshes sudo's timestamp cache
# in the background every 60s so a long multi-step run (many pacman/yay
# calls) never prompts again mid-run. Kills the background refresher on exit.
sudo_keepalive() {
  sudo -v
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  # Deliberately not `local` — the EXIT trap below reads it after this
  # function has returned, so it needs to still be in scope at script exit.
  sudo_keepalive_pid=$!
  trap 'kill "$sudo_keepalive_pid" 2>/dev/null' EXIT
}

# --- GPU detection --------------------------------------------------------
# Prints one line per detected GPU vendor ("nvidia" / "amd" / "intel"), based
# on lspci's VGA/3D/display controllers. A hybrid laptop (e.g. Intel + Nvidia
# Optimus) prints more than one line — order is nvidia, amd, intel.
#
# Matched by numeric PCI vendor ID (10de/1002/8086), not vendor name text —
# vendor name substrings like "ati" false-positive inside words such as
# "Corporation" that show up in every vendor's lspci line.
detect_gpu_vendors() {
  command -v lspci >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm pciutils >/dev/null
  local pci
  pci="$(lspci -nn 2>/dev/null | grep -iE 'VGA compatible controller|3D controller|Display controller' || true)"
  if grep -q '\[10de:' <<<"$pci"; then echo "nvidia"; fi
  if grep -q '\[1002:' <<<"$pci"; then echo "amd"; fi
  if grep -q '\[8086:' <<<"$pci"; then echo "intel"; fi
  return 0
}
