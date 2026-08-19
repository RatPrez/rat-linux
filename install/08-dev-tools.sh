#!/usr/bin/env bash
# Installs whatever was selected in the "dev-tools" category
# (packages/categories/dev-tools.toml) via install/03-category-picker.sh:
# pacman/AUR packages (Zed, GitHub Desktop, the optional HeidiSQL/Ghidra/
# gh extras) plus the two toolchains deliberately kept OUTSIDE pacman
# (Node via nvm, Rust via rustup), installed here as "script" items.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

cat_script_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    ok "nvm already installed"
  else
    log "Installing nvm + latest LTS Node"
    curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    nvm install --lts
  fi
}

cat_script_rustup() {
  if command -v rustup >/dev/null 2>&1; then
    ok "rustup already installed"
  else
    log "Installing rustup (stable toolchain)"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi
}

install_category "dev-tools" "$CATEGORIES_DIR/dev-tools.toml" cat_script
ok "Dev tools processed"
