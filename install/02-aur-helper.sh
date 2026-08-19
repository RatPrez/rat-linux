#!/usr/bin/env bash
# Install the yay AUR helper if missing.

if command -v yay >/dev/null 2>&1; then
  ok "yay already installed"
else
  log "Building yay from the AUR"
  tmpdir="$(mktemp -d)"
  # Non-fatal: without yay the AUR packages simply fail one by one and land
  # in the end-of-run summary, which beats aborting the whole install.
  if git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" \
     && ( cd "$tmpdir/yay" && makepkg -si --noconfirm ); then
    ok "yay installed"
  else
    warn "Failed to build yay; AUR packages will be skipped."
  fi
  rm -rf "$tmpdir"
fi
