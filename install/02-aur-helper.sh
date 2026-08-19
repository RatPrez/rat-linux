#!/usr/bin/env bash
# Install the yay AUR helper if missing.
#
# yay-bin is tried first: it ships a prebuilt binary, so it needs no Go
# toolchain and no large build under /tmp. Building yay from source pulls in
# go>=1.24, which is not part of base-devel, and /tmp is a RAM-sized tmpfs,
# so the source build is the fragile option on a fresh minimal install.
# Source yay is kept as a fallback in case yay-bin is unavailable.

if command -v yay >/dev/null 2>&1; then
  ok "yay already installed"
  return 0 2>/dev/null || exit 0
fi

rat_yay_log="$(mktemp -t rat-yay-XXXXXX.log)"

# Clone and build one AUR package by hand. Output is shown and also captured,
# so a failure is still readable after the install scrolls past it.
_rat_build_aur() {
  local pkg="$1" tmpdir status
  tmpdir="$(mktemp -d)"
  {
    git clone --depth=1 "https://aur.archlinux.org/$pkg.git" "$tmpdir/$pkg" \
      && ( cd "$tmpdir/$pkg" && makepkg -si --noconfirm )
  } 2>&1 | tee -a "$rat_yay_log"
  status=${PIPESTATUS[0]}
  rm -rf "$tmpdir"
  return "$status"
}

log "Installing yay (AUR helper)"
if _rat_build_aur yay-bin; then
  ok "yay installed (yay-bin)"
  rm -f "$rat_yay_log"
elif _rat_build_aur yay; then
  ok "yay installed (built from source)"
  rm -f "$rat_yay_log"
else
  warn "Could not install yay. Every AUR package will be skipped."
  warn "Build log kept at: $rat_yay_log"
  RAT_FAILED_PKGS+=("yay (AUR helper; see $rat_yay_log)")
fi
