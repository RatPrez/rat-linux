#!/usr/bin/env bash
# bash-it: community bash framework that drives the prompt/theme.
# https://github.com/Bash-it/bash-it
#
# Only the framework itself is cloned here — home/.bashrc (symlinked by the
# dotfiles module) sources it directly and points BASH_IT_THEME at
# home/.config/theme/tokyo-dark.theme.bash, so there's no need to run
# bash-it's own installer or let it touch your dotfiles.
#
# Part of the "theme" category (packages/categories/theme.toml, id
# "bash-it") — see install/03-category-picker.sh. If skipped, .bashrc's
# `[[ -f "$BASH_IT/bash_it.sh" ]]` guard keeps the shell working without it,
# just without the themed prompt.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

if ! cat_is_selected "theme" "bash-it" "$CATEGORIES_DIR/theme.toml"; then
  ok "bash-it not selected (theme category); skipping."
  return 0 2>/dev/null || exit 0
fi

bash_it_dir="$HOME/.bash_it"

if [[ -d "$bash_it_dir/.git" ]]; then
  ok "bash-it already installed"
else
  log "Cloning bash-it -> $bash_it_dir"
  git clone --depth=1 https://github.com/Bash-it/bash-it.git "$bash_it_dir"
  ok "bash-it cloned"
fi
