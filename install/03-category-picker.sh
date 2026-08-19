#!/usr/bin/env bash
# Quick vs Custom install picker, driven by gum. Walks the five categories and
# writes the resolved selection to $CATEGORY_STATE_FILE, which every later
# category-consuming module reads instead of installing everything
# unconditionally. Core modules never consult that file.
#
# Non-interactive runs (no /dev/tty) skip straight to Quick-install defaults.
#
# install.sh sources this module directly, before ui_init() takes over the
# screen with a scroll region, which gum's TUI cannot share.

# shellcheck source=../lib/categories.sh
source "$RAT_DIR/lib/categories.sh"

pac_install <<<"gum"

_cat_order=(dev-tools browsers gaming updater theme)
declare -A _cat_titles=(
  [dev-tools]="Dev tools"
  [browsers]="Browsers"
  [gaming]="Gaming"
  [updater]="Updater (rat commands)"
  [theme]="Theme"
)
declare -A _cat_desc=(
  [dev-tools]="Editors, toolchains, and optional extras (HeidiSQL, Ghidra)."
  [browsers]="Pick one or more."
  [gaming]="Steam, Vulkan, GameMode, and friends."
  [updater]="The rat CLI itself and what rat update/rat nvidia do."
  [theme]="TokyoNight overlay, WhiteSur cursors, bash-it, sleep/hibernate."
)
declare -A _cat_file=(
  [dev-tools]="$CATEGORIES_DIR/dev-tools.toml"
  [browsers]="$CATEGORIES_DIR/browsers.toml"
  [gaming]="$CATEGORIES_DIR/gaming.toml"
  [updater]="$CATEGORIES_DIR/updater.toml"
  [theme]="$CATEGORIES_DIR/theme.toml"
)

# Applies every category's manifest defaults into CAT_SELECTED (used by Quick
# install, and as the non-interactive fallback).
_apply_defaults() {
  local cat id
  for cat in "${_cat_order[@]}"; do
    while IFS= read -r id; do
      cat_set_selected "$cat" "$id" 1
    done < <(cat_default_ids "${_cat_file[$cat]}")
    while IFS= read -r id; do
      cat_set_selected "$cat" "$id" 0
    done < <(comm -23 <(cat_ids "${_cat_file[$cat]}" | sort) <(cat_default_ids "${_cat_file[$cat]}" | sort))
  done
}

# One-line summary of a category's current selection.
_cat_summary_line() {
  local cat="$1" file="${_cat_file[$cat]}" id name parts=()
  while IFS= read -r id; do
    name="$(cat_field "$file" "$id" name)"
    parts+=("$name")
  done < <(cat_selected_ids "$cat" "$file")
  if [[ ${#parts[@]} -eq 0 ]]; then
    echo "(none)"
  else
    local IFS=', '
    echo "${parts[*]}"
  fi
}

# A checklist built from repeated single-select `gum choose` calls: each item
# renders as "[x] Name" / "[ ] Name", and pressing enter flips it and redraws.
# gum choose has no native "enter toggles" mode, so this fakes it with a loop.
# A "Submit" row at the bottom ends it.
_run_custom_category() {
  local cat="$1" file="${_cat_file[$cat]}"
  local id name
  local ids=() names=()
  local -A state=()

  while IFS= read -r id; do
    name="$(cat_field "$file" "$id" name)"
    ids+=("$id")
    names+=("$name")
    if cat_is_selected "$cat" "$id" "$file"; then state[$id]=1; else state[$id]=0; fi
  done < <(cat_ids "$file")

  gum style --border rounded --margin "1 0" --padding "0 1" --border-foreground 212 \
    "${_cat_titles[$cat]}" "${_cat_desc[$cat]}" > /dev/tty

  local submit_label="Submit"
  local choices picked i any
  # gum puts the cursor on whatever --selected names, even in single-select
  # mode, so passing back the just-toggled row keeps the cursor there instead
  # of jumping to the top of the list on every redraw.
  local cursor_on=""

  while true; do
    choices=()
    for i in "${!ids[@]}"; do
      if [[ "${state[${ids[$i]}]}" == "1" ]]; then
        choices+=("[x] ${names[$i]}")
      else
        choices+=("[ ] ${names[$i]}")
      fi
    done
    choices+=("$submit_label")

    if [[ -n "$cursor_on" ]]; then
      picked="$(gum choose --header "Enter toggles an item. Pick '$submit_label' when done:" \
        --selected="$cursor_on" "${choices[@]}" < /dev/tty)"
    else
      picked="$(gum choose --header "Enter toggles an item. Pick '$submit_label' when done:" \
        "${choices[@]}" < /dev/tty)"
    fi

    if [[ "$picked" == "$submit_label" ]]; then
      if [[ "$cat" == "updater" ]]; then
        any=0
        for id in "${ids[@]}"; do [[ "${state[$id]}" == "1" ]] && any=1; done
        if [[ "$any" -eq 0 ]] \
          && ! gum confirm "You won't have 'rat update' or 'rat nvidia'. Continue with Updater empty?" < /dev/tty > /dev/tty; then
          continue
        fi
      fi
      break
    fi

    for i in "${!ids[@]}"; do
      if [[ "${choices[$i]}" == "$picked" ]]; then
        id="${ids[$i]}"
        [[ "${state[$id]}" == "1" ]] && state[$id]=0 || state[$id]=1
        if [[ "${state[$id]}" == "1" ]]; then
          cursor_on="[x] ${names[$i]}"
        else
          cursor_on="[ ] ${names[$i]}"
        fi
        break
      fi
    done
  done

  for id in "${ids[@]}"; do
    cat_set_selected "$cat" "$id" "${state[$id]}"
  done
}

_final_summary() {
  local lines=() cat
  for cat in "${_cat_order[@]}"; do
    lines+=("${_cat_titles[$cat]}: $(_cat_summary_line "$cat")")
  done
  gum style --border rounded --margin "1 0" --padding "0 1" --border-foreground 212 \
    "Selected for install:" "" "${lines[@]}" > /dev/tty
}

if [[ -r /dev/tty ]] && command -v gum >/dev/null 2>&1; then
  # Pre-seed from any existing state so a re-run doesn't just replay defaults.
  cat_state_load

  mode="$(gum choose --header "rat-linux install" "Quick install (defaults)" "Custom install" < /dev/tty)"

  if [[ "$mode" == "Quick install"* ]]; then
    _apply_defaults
    _final_summary
  else
    for cat in "${_cat_order[@]}"; do
      _run_custom_category "$cat"
    done
    _final_summary
    if ! gum confirm "Proceed with installation?" < /dev/tty > /dev/tty; then
      die "Aborted by user before installation started."
    fi
  fi
else
  log "No TTY; using category defaults without prompting."
  _apply_defaults
fi

cat_state_save
ok "Category selection saved -> $CATEGORY_STATE_FILE"
