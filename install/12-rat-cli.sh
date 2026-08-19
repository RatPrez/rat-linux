#!/usr/bin/env bash
# Link the `rat` control script onto PATH. Every patch that exists at
# install time actually runs at the end of install.sh (not skipped) — see
# patches/README.md — so there's no tracker to seed here.

mkdir -p "$HOME/.local/bin"
ln -sf "$RAT_DIR/bin/rat" "$HOME/.local/bin/rat"
ok "rat CLI linked -> ~/.local/bin/rat (run: rat help)"
