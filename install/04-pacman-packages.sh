#!/usr/bin/env bash
# Install everything from packages/pacman.txt, one package at a time so a single
# bad/missing package is skipped rather than aborting the batch.

count="$(read_list "$RAT_DIR/packages/pacman.txt" | grep -c . || true)"
log "Installing $count pacman packages (failures are skipped, not fatal)"
pac_install < <(read_list "$RAT_DIR/packages/pacman.txt")
ok "pacman packages processed"
