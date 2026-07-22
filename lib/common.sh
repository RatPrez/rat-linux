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
