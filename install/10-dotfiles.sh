#!/usr/bin/env bash
# Symlink dotfiles from the repo's home/ into your $HOME, so config is always
# read live from this checkout ($RAT_DIR) — edit a file here (or `rat update`
# to pull new commits) and every symlinked app picks it up immediately, no
# re-copy step needed.
#
# Everything under home/ mirrors your real home directory 1:1, e.g.
#   home/.config/zed/settings.json  ->  ~/.config/zed/settings.json (symlink)
#   home/.clang-format              ->  ~/.clang-format (symlink)
#
# A real (non-rat-linux) file already at the destination is backed up once
# (<file>.rat.bak-<timestamp>) before being replaced with the symlink. Links
# that already point at the right place are left alone, which keeps re-runs
# quiet and idempotent.

src="$RAT_DIR/home"

if [[ ! -d "$src" ]]; then
  warn "No home/ directory in the repo; skipping dotfiles."
  return 0 2>/dev/null || exit 0
fi

log "Symlinking dotfiles from home/ into $HOME"
ts="$(date +%Y%m%d%H%M%S)"
count=0

# Walk every regular file under home/ and symlink it into $HOME, preserving
# the relative path (-print0/-d '' so paths with spaces survive).
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"            # path relative to home/
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
