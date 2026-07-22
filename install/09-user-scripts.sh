#!/usr/bin/env bash
# Install the repo's bin/ commands into /usr/local/bin so they're on PATH
# everywhere (omarchy-style). Add new commands by dropping a script in bin/.

shopt -s nullglob
scripts=("$RAT_DIR"/bin/*)

if [[ ${#scripts[@]} -eq 0 ]]; then
  ok "no bin/ scripts to install"
  return 0 2>/dev/null || exit 0
fi

log "Installing ${#scripts[@]} command(s) to /usr/local/bin"
for f in "${scripts[@]}"; do
  [[ -f "$f" ]] || continue
  name="$(basename "$f")"
  sudo install -Dm755 "$f" "/usr/local/bin/$name"
  ok "installed command: $name"
done
