#!/usr/bin/env bash
# Category manifest parsing + selection state, shared by the category picker,
# every category-consuming module, and `bin/rat` (which reads the "updater"
# category's toggles at runtime).
#
# Manifest format: packages/categories/<name>.toml, one [[item]] block per entry:
#   [[item]]
#   id = "brave"           # stable key, used in the state file
#   name = "Brave"         # shown in the gum picker
#   source = "pacman"      # pacman | aur | flatpak | script | toggle | custom
#   package = "brave-bin"  # space-separated name(s); omitted for script/toggle/custom
#   default = true         # preselected for Quick install and fresh Custom pickers
#   description = "..."    # optional

CATEGORIES_DIR="$RAT_DIR/packages/categories"
CATEGORY_STATE_FILE="$HOME/.local/state/rat-linux/selected-categories.json"

# Populated lazily by cat_state_load. Keys are "<category>.<id>", values "1"/"0".
declare -gA CAT_SELECTED=()
_cat_state_loaded=0

# Emits one TSV line per [[item]]: id, name, source, package, default(1|0), description
cat_parse() {
  local file="$1"
  [[ -f "$file" ]] || die "Category manifest not found: $file"
  awk '
    function flush() {
      if (id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", id, name, source, package, (isdefault=="true"?1:0), desc
      }
      id=""; name=""; source=""; package=""; isdefault="false"; desc=""
    }
    /^\[\[item\]\]/ { flush(); next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      eq = index(line, "=")
      if (eq == 0) next
      key = substr(line, 1, eq - 1)
      val = substr(line, eq + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      sub(/[[:space:]]*#.*$/, "", val)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      if (val ~ /^".*"$/) { val = substr(val, 2, length(val) - 2) }
      if (key == "id") id = val
      else if (key == "name") name = val
      else if (key == "source") source = val
      else if (key == "package") package = val
      else if (key == "default") isdefault = val
      else if (key == "description") desc = val
    }
    END { flush() }
  ' "$file"
}

# All item ids in a manifest, in file order.
cat_ids() { cat_parse "$1" | cut -f1; }

# Ids whose default = true.
cat_default_ids() { cat_parse "$1" | awk -F'\t' '$5 == 1 { print $1 }'; }

# One field for a given id.
cat_field() {
  local file="$1" id="$2" field="$3" col
  case "$field" in
    id) col=1 ;; name) col=2 ;; source) col=3 ;; package) col=4 ;;
    default) col=5 ;; description) col=6 ;;
    *) die "cat_field: unknown field $field" ;;
  esac
  cat_parse "$file" | awk -F'\t' -v id="$id" -v c="$col" '$1 == id { print $c; exit }'
}

# Loads $CATEGORY_STATE_FILE (if present) into CAT_SELECTED. Safe to call
# repeatedly; only parses the file once per process.
cat_state_load() {
  (( _cat_state_loaded )) && return 0
  _cat_state_loaded=1
  [[ -f "$CATEGORY_STATE_FILE" ]] || return 0
  local key val
  while IFS=$'\t' read -r key val; do
    [[ -n "$key" ]] || continue
    CAT_SELECTED["$key"]="$val"
  done < <(grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*(true|false)' "$CATEGORY_STATE_FILE" \
             | sed -E 's/^"([^"]+)"[[:space:]]*:[[:space:]]*(true|false)$/\1\t\2/' \
             | sed -E 's/\ttrue$/\t1/; s/\tfalse$/\t0/')
}

# Writes CAT_SELECTED out as JSON: {"category.id": true, ...}.
cat_state_save() {
  mkdir -p "$(dirname "$CATEGORY_STATE_FILE")"
  {
    echo "{"
    local keys=() k first=1
    for k in "${!CAT_SELECTED[@]}"; do keys+=("$k"); done
    IFS=$'\n' keys=($(sort <<<"${keys[*]}")); unset IFS
    for k in "${keys[@]}"; do
      local v="${CAT_SELECTED[$k]}"
      [[ "$v" == "1" ]] && v="true" || v="false"
      (( first )) || echo ","
      first=0
      printf '  "%s": %s' "$k" "$v"
    done
    echo ""
    echo "}"
  } > "$CATEGORY_STATE_FILE"
}

# True if <category>.<id> is selected: state file wins if present, otherwise
# the manifest's own default, so a module run standalone (state file missing)
# still does something sane instead of installing nothing.
cat_is_selected() {
  local category="$1" id="$2" file="$3"
  cat_state_load
  local key="$category.$id"
  if [[ -n "${CAT_SELECTED[$key]+x}" ]]; then
    [[ "${CAT_SELECTED[$key]}" == "1" ]]
    return
  fi
  [[ "$(cat_field "$file" "$id" default)" == "1" ]]
}

# Record a selection (val: 1|0).
cat_set_selected() {
  local category="$1" id="$2" val="$3"
  CAT_SELECTED["$category.$id"]="$val"
}

# Ids in a manifest that are currently selected.
cat_selected_ids() {
  local category="$1" file="$2" id
  while IFS= read -r id; do
    cat_is_selected "$category" "$id" "$file" && echo "$id"
  done < <(cat_ids "$file")
}

# Installs every currently-selected item in a manifest. "script" items call a
# function named "<script_prefix>_<id>" that the caller must have defined.
# "toggle" and "custom" items are no-ops here: toggles are read live by their
# consumer (bin/rat), and custom items are handled by the calling module.
install_category() {
  local category="$1" file="$2" script_prefix="${3:-}"
  local id source package pkg
  local pac_pkgs=() aur_pkgs=() flatpak_pkgs=()

  while IFS= read -r id; do
    source="$(cat_field "$file" "$id" source)"
    package="$(cat_field "$file" "$id" package)"
    case "$source" in
      pacman)  for pkg in $package; do pac_pkgs+=("$pkg"); done ;;
      aur)     for pkg in $package; do aur_pkgs+=("$pkg"); done ;;
      flatpak) for pkg in $package; do flatpak_pkgs+=("$pkg"); done ;;
      script)
        local fn="${script_prefix}_${id}"
        if [[ -n "$script_prefix" ]] && declare -F "$fn" >/dev/null; then
          "$fn"
        else
          warn "No installer defined for script item '$id' in $category; skipping."
        fi
        ;;
      toggle|custom) : ;;
      *) warn "Unknown source '$source' for item '$id' in $category; skipping." ;;
    esac
  done < <(cat_selected_ids "$category" "$file")

  if [[ ${#pac_pkgs[@]} -gt 0 ]]; then
    log "$category: installing ${#pac_pkgs[@]} pacman package(s)"
    printf '%s\n' "${pac_pkgs[@]}" | pac_install
  fi
  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    log "$category: installing ${#aur_pkgs[@]} AUR package(s)"
    printf '%s\n' "${aur_pkgs[@]}" | aur_install
  fi
  if [[ ${#flatpak_pkgs[@]} -gt 0 ]]; then
    if command -v flatpak >/dev/null 2>&1; then
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      log "$category: installing ${#flatpak_pkgs[@]} Flatpak app(s)"
      for pkg in "${flatpak_pkgs[@]}"; do
        if flatpak install -y --noninteractive flathub "$pkg"; then
          ok "flatpak: $pkg"
        else
          warn "flatpak FAILED: $pkg  (skipping, continuing with the rest)"
          RAT_FAILED_PKGS+=("$pkg")
        fi
      done
    else
      warn "flatpak not installed; skipping $category Flatpak app(s)."
    fi
  fi
}
