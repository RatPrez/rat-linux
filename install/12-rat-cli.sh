#!/usr/bin/env bash
# Link the `rat` control script onto PATH, and seed the patch tracker.
#
# Seeding matters: a fresh install already reflects everything currently in
# patches/, so those must NOT be replayed — only patches added *after* this
# point should ever run, via `rat update`. See patches/README.md.

mkdir -p "$HOME/.local/bin"
ln -sf "$RAT_DIR/bin/rat" "$HOME/.local/bin/rat"
ok "rat CLI linked -> ~/.local/bin/rat (run: rat help)"

state_dir="$HOME/.local/state/rat-linux"
mkdir -p "$state_dir"
level_file="$state_dir/patch-level"

if [[ ! -f "$level_file" ]]; then
  shopt -s nullglob
  patches=("$RAT_DIR"/patches/[0-9][0-9][0-9][0-9]-*.sh)
  shopt -u nullglob
  highest=0
  for p in "${patches[@]}"; do
    n="$(basename "$p")"; n="${n%%-*}"
    n=$((10#$n))
    (( n > highest )) && highest=$n
  done
  echo "$highest" > "$level_file"
  ok "Patch tracker seeded at $highest (this install already reflects that state)"
fi
