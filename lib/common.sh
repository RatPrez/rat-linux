#!/usr/bin/env bash
# Shared helpers + config. Sourced by install.sh and every install/*.sh module.

: "${RAT_REPO:=https://github.com/RatPrez/rat-linux.git}"
: "${RAT_BRANCH:=master}"
: "${RAT_DIR:=$HOME/.local/share/rat-linux}"

_c_reset=$'\033[0m'; _c_blue=$'\033[1;34m'; _c_green=$'\033[1;32m'
_c_yellow=$'\033[1;33m'; _c_red=$'\033[1;31m'

log()  { printf '%s==>%s %s\n' "$_c_blue"   "$_c_reset" "$*"; }
ok()   { printf '%s ok%s %s\n'  "$_c_green"  "$_c_reset" "$*"; }
warn() { printf '%s!!%s %s\n'   "$_c_yellow" "$_c_reset" "$*" >&2; }
die()  { printf '%serr%s %s\n'  "$_c_red"    "$_c_reset" "$*" >&2; exit 1; }

# True if a controlling terminal is actually usable. Testing -r /dev/tty is
# not enough: the node can be readable while the process has no controlling
# terminal, so the test passes and every later read and write fails.
have_tty() { { : < /dev/tty; } 2>/dev/null; }

require_not_root() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run as your normal user (it'll sudo when needed), not root."
}

# `trap ... EXIT` overwrites any previously-set EXIT trap, which breaks once
# more than one thing needs to clean up on exit. add_exit_trap lets each of
# them register independently.
_rat_exit_hooks=()
add_exit_trap() {
  _rat_exit_hooks+=("$1")
  trap '_rat_run_exit_hooks' EXIT
}
_rat_run_exit_hooks() {
  local h
  for h in "${_rat_exit_hooks[@]}"; do eval "$h"; done
}

# Read a package list file: strips comments (#...) and blank lines.
# Usage: mapfile -t pkgs < <(read_list packages/pacman.txt)
read_list() {
  local f="$1"
  [[ -f "$f" ]] || die "Package list not found: $f"
  sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$f"
}

# Packages are installed one at a time so a single failure (missing package,
# broken AUR build, network hiccup) is reported and skipped instead of
# aborting the whole run. Failures accumulate here and are summarized by
# install.sh at the end.
RAT_FAILED_PKGS=()

# Run installer "$1 ..." for each package on stdin, recording failures.
_install_each() {
  local label="$1"; shift
  local installer=("$@")
  local pkg
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

pac_install() { _install_each "pacman" sudo pacman -S --needed --noconfirm; }
aur_install() { _install_each "aur" yay -S --needed --noconfirm; }

# Prompts for the sudo password once, then refreshes sudo's timestamp cache
# in the background every 60s so a long run never prompts again mid-way.
# Nothing is stored; the background refresher is killed on exit.
sudo_keepalive() {
  sudo -v
  # `set +e`: this subshell otherwise inherits errexit from the sourcing
  # script, so one transient `sudo -n true` failure would silently kill the
  # refresher and sudo would start prompting again out of nowhere.
  # Output goes to /dev/null so the refresher never holds a consuming pipe
  # open; otherwise `./install.sh | tee log` stalls if the script dies on a
  # signal before the exit hook can kill it.
  ( set +e; while true; do sudo -n true 2>/dev/null; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) >/dev/null 2>&1 &
  # Deliberately not `local`: the exit hook reads it after this returns.
  sudo_keepalive_pid=$!
  add_exit_trap 'kill "$sudo_keepalive_pid" 2>/dev/null'
}

# Prints one line per detected GPU vendor ("nvidia" / "amd" / "intel"), based
# on lspci's VGA/3D/display controllers. A hybrid laptop prints more than one.
#
# Matched by numeric PCI vendor ID, not vendor name text: substrings like
# "ati" false-positive inside words such as "Corporation".
detect_gpu_vendors() {
  command -v lspci >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm pciutils >/dev/null
  local pci
  pci="$(lspci -nn 2>/dev/null | grep -iE 'VGA compatible controller|3D controller|Display controller' || true)"
  if grep -q '\[10de:' <<<"$pci"; then echo "nvidia"; fi
  if grep -q '\[1002:' <<<"$pci"; then echo "amd"; fi
  if grep -q '\[8086:' <<<"$pci"; then echo "intel"; fi
  return 0
}
