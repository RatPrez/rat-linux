#!/usr/bin/env bash
# Installs whatever was selected in the "dev-tools" category
# (packages/categories/dev-tools.toml): pacman/AUR packages, plus the two
# toolchains deliberately kept outside pacman (Node via nvm, Rust via
# rustup), which are wired up here as "script" items.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

cat_script_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    ok "nvm already installed"
    return 0
  fi
  log "Installing nvm + latest LTS Node"
  if ! curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
    warn "nvm installer failed; skipping Node."
    return 0
  fi
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    warn "nvm.sh missing after install; skipping Node LTS."
    return 0
  fi
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm install --lts || warn "nvm install --lts failed; install Node by hand."
}

cat_script_rustup() {
  if command -v rustup >/dev/null 2>&1; then
    ok "rustup already installed"
    return 0
  fi
  log "Installing rustup (stable toolchain)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    || warn "rustup installer failed; install Rust by hand."
}

install_category "dev-tools" "$CATEGORIES_DIR/dev-tools.toml" cat_script
ok "Dev tools processed"
