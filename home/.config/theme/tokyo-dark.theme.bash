# shellcheck shell=bash
# shellcheck disable=SC2034 # Expected behavior for themes.
#
# Tokyo Dark bash-it theme.
# Based on the "bobby" theme (~/.bash_it/themes/bobby), recolored with the
# truecolor palette from home/.config/alacritty/alacritty.toml (Tokyo Night).

tokyodark_black="\[\e[38;2;68;75;106m\]"     # TokyoNight bright black  #444b6a
tokyodark_red="\[\e[38;2;255;122;147m\]"     # TokyoNight bright red    #ff7a93
tokyodark_green="\[\e[38;2;185;242;124m\]"   # TokyoNight bright green  #b9f27c
tokyodark_yellow="\[\e[38;2;255;158;100m\]"  # TokyoNight bright yellow #ff9e64
tokyodark_blue="\[\e[38;2;125;166;255m\]"    # TokyoNight bright blue   #7da6ff
tokyodark_magenta="\[\e[38;2;187;154;247m\]" # TokyoNight bright magenta #bb9af7
tokyodark_cyan="\[\e[38;2;13;185;215m\]"     # TokyoNight bright cyan   #0db9d7
tokyodark_white="\[\e[38;2;172;176;208m\]"   # TokyoNight bright white  #acb0d0
tokyodark_grey="\[\e[38;2;50;52;74m\]"       # TokyoNight normal black  #32344a
tokyodark_reset="\[\e[0m\]"

SCM_GIT_CHAR=$''

SCM_THEME_PROMPT_DIRTY=" ${tokyodark_red}✗"
SCM_THEME_PROMPT_CLEAN=" ${tokyodark_green}✓"
SCM_THEME_PROMPT_PREFIX=" ${tokyodark_grey}|"
SCM_THEME_PROMPT_SUFFIX="${tokyodark_grey}|"

GIT_THEME_PROMPT_DIRTY=" ${tokyodark_red}✗"
GIT_THEME_PROMPT_CLEAN=" ${tokyodark_green}✓"
GIT_THEME_PROMPT_PREFIX=" ${tokyodark_grey}|"
GIT_THEME_PROMPT_SUFFIX="${tokyodark_grey}|"

RVM_THEME_PROMPT_PREFIX="|"
RVM_THEME_PROMPT_SUFFIX="|"

function __tokyo_dark_clock() {
	printf '%s' "$(clock_prompt) "

	if [[ "${THEME_SHOW_CLOCK_CHAR:-}" == "true" ]]; then
		printf '%s' "$(clock_char) "
	fi
}

function prompt_command() {
	PS1="\n$(__tokyo_dark_clock)"
	PS1+="${tokyodark_magenta}\h "
	PS1+="${tokyodark_reset}in "
	PS1+="${tokyodark_green}\w\n"
	PS1+="${tokyodark_cyan}$(scm_prompt_char_info) "
	PS1+="${tokyodark_green}→${tokyodark_reset} "
}

: "${THEME_SHOW_CLOCK_CHAR:="true"}"
: "${THEME_CLOCK_CHAR:="🐀"}"
: "${THEME_CLOCK_CHAR_COLOR:=${tokyodark_red}}"
: "${THEME_CLOCK_COLOR:=${tokyodark_cyan}}"
: "${THEME_CLOCK_FORMAT:="%H:%M:%S"}"

safe_append_prompt_command prompt_command
