#!/usr/bin/env bash
# Language toolchains that you deliberately want OUTSIDE pacman:
#   - Node via nvm
#   - Rust via rustup

# --- nvm + latest LTS Node -----------------------------------------------------
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

# --- rustup --------------------------------------------------------------------
if command -v rustup >/dev/null 2>&1; then
  ok "rustup already installed"
else
  log "Installing rustup (stable toolchain)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

ok "Dev tools installed"
