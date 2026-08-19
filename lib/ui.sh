#!/usr/bin/env bash
# Full-screen install UI: ascii art fixed up top, log output scrolling in the
# middle, a progress bar pinned to the last line. Sourced by install.sh only
# (individual install/*.sh modules just keep calling log/ok/warn/die from
# common.sh as normal -- they don't need to know this is active).
#
# Technique: a VT100 scroll region (DECSTBM, `ESC [ top ; bottom r`) confines
# scrolling to the middle band, so printing a newline there never touches the
# art or the progress bar. This works on a bare Arch console (TERM=linux),
# not just full terminal emulators -- the Linux console driver implements
# DECSTBM, and tput/terminfo ship with ncurses, which bash/readline already
# pull in on any Arch install, so there's no new dependency.
#
# Set RAT_NO_UI=1 to skip this and get the old plain scrolling output.

RAT_ASCII_ART='   /\_/\
  ( o.o )
   > ^ <
  RAT-LINUX'

_rat_ui_active=0
_rat_ui_total=0
_rat_ui_rows=0
_rat_ui_scroll_top=0

# True if stdout is an interactive terminal with room for the layout.
ui_supported() {
  [[ -z "${RAT_NO_UI:-}" ]] || return 1
  [[ -t 1 ]] || return 1
  local rows cols art_lines
  rows="$(tput lines 2>/dev/null || echo 0)"
  cols="$(tput cols 2>/dev/null || echo 0)"
  art_lines="$(awk 'END{print NR}' <<<"$RAT_ASCII_ART")"
  (( rows >= art_lines + 6 && cols >= 30 ))
}

# Draw the art, carve out the scroll region, show progress at 0. Call once
# with the total number of steps the progress bar should track.
ui_init() {
  _rat_ui_total="${1:-0}"
  ui_supported || return 0

  _rat_ui_rows="$(tput lines)"
  local cols; cols="$(tput cols)"

  tput civis
  tput clear

  local line row=1 pad
  while IFS= read -r line; do
    pad=$(( (cols - ${#line}) / 2 ))
    (( pad < 0 )) && pad=0
    tput cup "$((row - 1))" "$pad"
    printf '%s' "$line"
    ((row++))
  done <<<"$RAT_ASCII_ART"

  # Region: [art] blank [scroll region for log()] blank [progress bar]
  _rat_ui_scroll_top=$((row + 1))
  local scroll_bottom=$((_rat_ui_rows - 2))
  printf '\033[%d;%dr' "$_rat_ui_scroll_top" "$scroll_bottom"
  tput cup "$((_rat_ui_scroll_top - 1))" 0

  _rat_ui_active=1
  add_exit_trap ui_cleanup
  ui_progress 0 "starting"
}

# ui_progress <current> [label]
ui_progress() {
  (( _rat_ui_active )) || return 0
  local current="$1" label="${2:-}"
  local total=$_rat_ui_total cols; cols="$(tput cols)"
  local pct=0
  (( total > 0 )) && pct=$(( current * 100 / total ))

  # Fixed chrome around the bar+label is 10 cols: " [" "] " "100" "%" "  ".
  # Split what's left 60/40 between the bar and the label so long module
  # names (e.g. "03-category-picker") aren't clipped by an oversized bar.
  local avail=$((cols - 10))
  local bar_width=$((avail * 3 / 5))
  (( bar_width < 10 )) && bar_width=10
  local filled=$(( bar_width * pct / 100 ))
  local bar
  bar="$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' "$((bar_width - filled))" '')"

  local max_label=$((avail - bar_width))
  (( max_label < 0 )) && max_label=0
  label="${label:0:max_label}"

  tput sc
  tput cup "$((_rat_ui_rows - 1))" 0
  tput el
  printf ' [%s] %3d%%  %s' "$bar" "$pct" "$label"
  tput rc
}

# Restore the terminal to normal full-screen scrolling. Registered as an exit
# hook by ui_init, so this runs automatically on normal exit, error, or
# Ctrl-C -- never call it directly.
ui_cleanup() {
  (( _rat_ui_active )) || return 0
  _rat_ui_active=0
  printf '\033[r'
  tput cup "$((_rat_ui_rows - 1))" 0
  tput cnorm
}
