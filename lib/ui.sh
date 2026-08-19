#!/usr/bin/env bash
# Full-screen install UI: ascii art fixed up top, log output scrolling in the
# middle, a progress bar pinned to the last line. Sourced by install.sh only;
# install/*.sh modules just keep calling log/ok/warn/die as normal.
#
# A VT100 scroll region (DECSTBM) confines scrolling to the middle band, so
# printing a newline there never touches the art or the progress bar. That
# works on a bare Arch console (TERM=linux) as well as in a terminal emulator.
#
# gum draws the boxed chrome (header, summary). The bar itself is drawn with
# raw escapes rather than gum, since it redraws on every step and needs to
# position the cursor on a fixed line.
#
# Set RAT_NO_UI=1 to skip this and get plain scrolling output.

RAT_ASCII_ART=(
  '   /\_/\'
  '  ( o.o )'
  '   > ^ <'
  ''
  'R A T - L I N U X'
)

# 256-colour palette, matching the pink gum uses in the category picker.
_rat_c_accent=$'\033[38;5;212m'
_rat_c_track=$'\033[38;5;238m'
_rat_c_label=$'\033[38;5;252m'
_rat_c_dim=$'\033[38;5;245m'
_rat_c_off=$'\033[0m'

_rat_ui_active=0
_rat_ui_total=0
_rat_ui_rows=0
_rat_ui_scroll_top=0
# Runs of bar/track characters, sliced with ${var:0:n} to size the bar. Built
# once in ui_init rather than with `tr`, which is byte-oriented and would tear
# multibyte block characters apart.
_rat_ui_fill_run=''
_rat_ui_track_run=''
_rat_ui_mark_run='>'
_rat_ui_mark_done='ok'

_rat_has_gum() { command -v gum >/dev/null 2>&1; }

# True if stdout is an interactive terminal with room for the layout.
ui_supported() {
  [[ -z "${RAT_NO_UI:-}" ]] || return 1
  [[ -t 1 ]] || return 1
  local rows cols
  rows="$(tput lines 2>/dev/null || echo 0)"
  cols="$(tput cols 2>/dev/null || echo 0)"
  (( rows >= ${#RAT_ASCII_ART[@]} + 8 && cols >= 40 ))
}

# The header, as it will be printed. gum boxes it when available. The box is
# kept narrow and centred by hand: --align centres the art inside the box, but
# gum has no way to centre the box itself, so that's what the left margin is.
_rat_ui_header() {
  local cols="$1"
  local box=34
  (( box > cols )) && box=$cols
  if _rat_has_gum; then
    gum style --border rounded --border-foreground 212 --foreground 255 \
      --align center --width "$((box - 2))" --padding "0 1" \
      --margin "0 0 0 $(( (cols - box) / 2 ))" \
      "${RAT_ASCII_ART[@]}"
  else
    printf '%s\n' "${RAT_ASCII_ART[@]}"
  fi
}

# Draw the art, carve out the scroll region, show progress at 0. Call once
# with the total number of steps the progress bar should track.
ui_init() {
  _rat_ui_total="${1:-0}"
  ui_supported || return 0

  _rat_ui_rows="$(tput lines)"
  local cols; cols="$(tput cols)"

  # Block-drawing characters look better, but the bare Linux console font is
  # patchy about them, so stay with ASCII there.
  local fill='#' track='-' i
  if [[ "${TERM:-}" != "linux" ]]; then
    fill='█'
    track='░'
    _rat_ui_mark_run='▸'
    _rat_ui_mark_done='✓'
  fi
  for ((i = 0; i < cols; i++)); do
    _rat_ui_fill_run+="$fill"
    _rat_ui_track_run+="$track"
  done

  tput civis
  tput clear

  local header rows_used
  header="$(_rat_ui_header "$cols")"
  printf '%s\n' "$header"
  rows_used="$(awk 'END{print NR}' <<<"$header")"

  # Region: [header] blank [scroll region for log()] blank [progress bar]
  _rat_ui_scroll_top=$((rows_used + 2))
  local scroll_bottom=$((_rat_ui_rows - 2))
  printf '\033[%d;%dr' "$_rat_ui_scroll_top" "$scroll_bottom"
  tput cup "$((_rat_ui_scroll_top - 1))" 0

  _rat_ui_active=1
  add_exit_trap ui_cleanup
  _rat_ui_render 0 '' "getting started"
}

# _rat_ui_render <completed> <marker> <label>
_rat_ui_render() {
  (( _rat_ui_active )) || return 0
  local current="$1" marker="$2" label="$3"
  local total=$_rat_ui_total cols; cols="$(tput cols)"
  local pct=0
  (( total > 0 )) && pct=$(( current * 100 / total ))

  # Fixed chrome is 20 cols: leading space, bar brackets, "100%", the "n/m"
  # counter, and the gaps between them. Split the rest 3:2 between bar and
  # label so long module names ("03-category-picker") aren't clipped.
  local avail=$((cols - 20))
  (( avail < 20 )) && avail=20
  local bar_width=$((avail * 3 / 5))
  (( bar_width < 10 )) && bar_width=10
  local filled=$(( bar_width * pct / 100 ))

  local bar_on="${_rat_ui_fill_run:0:filled}"
  local bar_off="${_rat_ui_track_run:0:$((bar_width - filled))}"

  local max_label=$((avail - bar_width))
  (( max_label < 0 )) && max_label=0
  [[ -n "$marker" ]] && label="$marker $label"
  label="${label:0:max_label}"

  tput sc
  tput cup "$((_rat_ui_rows - 1))" 0
  tput el
  printf ' %s%s%s%s%s  %s%3d%%%s %s%*d/%d%s  %s%s%s' \
    "$_rat_c_accent" "$bar_on" "$_rat_c_track" "$bar_off" "$_rat_c_off" \
    "$_rat_c_accent" "$pct" "$_rat_c_off" \
    "$_rat_c_dim" "${#_rat_ui_total}" "$current" "$_rat_ui_total" "$_rat_c_off" \
    "$_rat_c_label" "$label" "$_rat_c_off"
  tput rc
}

# ui_step <completed> [label]: the named module is about to start.
ui_step() { _rat_ui_render "$1" "$_rat_ui_mark_run" "${2:-}"; }

# ui_progress <completed> [label]: the named module just finished.
ui_progress() { _rat_ui_render "$1" "$_rat_ui_mark_done" "${2:-}"; }

# ui_box <title> [line ...]: a gum-boxed message, for end-of-run summaries.
# Safe to call after ui_cleanup, and degrades to plain lines without gum.
ui_box() {
  local title="$1"; shift
  if _rat_has_gum && [[ -t 1 ]]; then
    gum style --border rounded --border-foreground 212 --padding "0 2" \
      --margin "1 0" "$title" "" "$@"
  else
    printf '%s\n' "$title" "$@"
  fi
}

# Restore the terminal to normal full-screen scrolling. Registered as an exit
# hook by ui_init, so it also runs on error or Ctrl-C.
ui_cleanup() {
  (( _rat_ui_active )) || return 0
  _rat_ui_active=0
  printf '\033[r'
  # Scroll up one line so the finished bar stays on screen above the prompt.
  tput cup "$((_rat_ui_rows - 1))" 0
  printf '\n'
  tput cnorm
}
