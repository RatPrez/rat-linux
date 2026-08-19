#!/usr/bin/env bash
# Symlink dotfiles from the repo's home/ into $HOME, so config is read live
# from this checkout: editing a file here (or `rat update` pulling new
# commits) applies immediately, with no re-copy step.
#
# Everything under home/ mirrors your real home directory 1:1, e.g.
#   home/.config/zed/settings.json  ->  ~/.config/zed/settings.json
#
# A real (non-symlink) file already at the destination is backed up once as
# <file>.rat.bak-<timestamp> before being replaced. Links already pointing at
# the right place are left alone, which keeps re-runs idempotent.

src="$RAT_DIR/home"

if [[ ! -d "$src" ]]; then
  warn "No home/ directory in the repo; skipping dotfiles."
  return 0 2>/dev/null || exit 0
fi

log "Symlinking dotfiles from home/ into $HOME"
ts="$(date +%Y%m%d%H%M%S)"
count=0

# -print0 / -d '' so paths with spaces survive.
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"
  dest="$HOME/$rel"

  if [[ -L "$dest" ]]; then
    [[ "$(readlink "$dest")" == "$file" ]] && continue   # already linked
    rm -f "$dest"
  elif [[ -e "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    mv "$dest" "$dest.rat.bak-$ts"
    warn "backed up existing $rel -> $rel.rat.bak-$ts"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$file" "$dest"
  ok "dotfile: $rel -> (symlink)"
  count=$((count + 1))
done < <(find "$src" -type f -print0)

ok "Dotfiles symlinked ($count updated)."
