#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(dircolors "$HOME/.config/theme/dircolors")"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[ -f "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"

# Arch names the Zed CLI 'zeditor'
alias zed='zeditor'

BASH_IT="$HOME/.bash_it"
export BASH_IT_THEME="$HOME/.config/theme/tokyo-dark.theme.bash"

# Don't check mail when opening terminal.
unset MAILCHECK

export IRC_CLIENT='irssi'
TODO="t"

# Optional: the "theme" category can skip installing bash-it entirely.
[[ -f "$BASH_IT/bash_it.sh" ]] && source "$BASH_IT/bash_it.sh"
