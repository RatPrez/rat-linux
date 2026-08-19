#!/usr/bin/env bash
# bash-it (https://github.com/Bash-it/bash-it), the framework driving the
# prompt theme. Only the framework is cloned here: home/.bashrc sources it
# directly and sets BASH_IT_THEME itself, so bash-it's own installer never
# runs and never touches your dotfiles.
#
# Part of the "theme" category. If skipped, .bashrc's existence guard keeps
# the shell working, just without the themed prompt.

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
  if git clone --depth=1 https://github.com/Bash-it/bash-it.git "$bash_it_dir"; then
    ok "bash-it cloned"
  else
    warn "Failed to clone bash-it; the shell works, just without the theme."
  fi
fi
