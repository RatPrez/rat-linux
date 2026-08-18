#!/usr/bin/env bash
# bash-it: community bash framework that drives the prompt/theme.
# https://github.com/Bash-it/bash-it
#
# Only the framework itself is cloned here — home/.bashrc (symlinked by the
# next module) sources it directly and points BASH_IT_THEME at
# home/.config/theme/tokyo-dark.theme.bash, so there's no need to run
# bash-it's own installer or let it touch your dotfiles.

bash_it_dir="$HOME/.bash_it"

if [[ -d "$bash_it_dir/.git" ]]; then
  ok "bash-it already installed"
else
  log "Cloning bash-it -> $bash_it_dir"
  git clone --depth=1 https://github.com/Bash-it/bash-it.git "$bash_it_dir"
  ok "bash-it cloned"
fi
