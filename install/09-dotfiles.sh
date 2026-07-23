#!/usr/bin/env bash
# Copy dotfiles from the repo's home/ into your $HOME.
#
# Everything under home/ mirrors your real home directory 1:1, e.g.
#   home/.config/zed/settings.json  ->  ~/.config/zed/settings.json
#   home/.clang-format              ->  ~/.clang-format
#
# Existing files are backed up (<file>.rat.bak-<timestamp>) before being
# overwritten, so nothing is silently lost. Files that are already identical
# are skipped, which keeps re-runs quiet and idempotent.

src="$RAT_DIR/home"

if [[ ! -d "$src" ]]; then
  warn "No home/ directory in the repo; skipping dotfiles."
  return 0 2>/dev/null || exit 0
fi

log "Copying dotfiles from home/ into $HOME"
ts="$(date +%Y%m%d%H%M%S)"

# Walk every regular file under home/ and mirror it into $HOME, preserving the
# relative path (-print0/-d '' so paths with spaces survive).
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"            # path relative to home/
  dest="$HOME/$rel"

  if [[ -e "$dest" ]] && cmp -s "$file" "$dest"; then
    continue                        # already up to date
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    cp -a "$dest" "$dest.rat.bak-$ts"
    warn "backed up existing $rel -> $rel.rat.bak-$ts"
  fi

  cp -a "$file" "$dest"
  ok "dotfile: $rel"
done < <(find "$src" -type f -print0)

ok "Dotfiles copied."
