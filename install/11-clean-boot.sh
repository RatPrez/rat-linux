#!/usr/bin/env bash
# Optional: quiet the boot (suppress scrolling text; errors/hangs still show).
# Limine only — see bin/clean-boot. Prompted y/N by default; set
# RAT_CLEAN_BOOT=yes (or =no) to skip the prompt on unattended runs.

# Only relevant on Limine — skip silently otherwise (e.g. GRUB/systemd-boot).
has_limine=""
for c in /boot/limine.conf /boot/EFI/limine/limine.conf /boot/EFI/BOOT/limine.conf \
         /boot/limine.cfg /boot/EFI/limine/limine.cfg; do
  if sudo test -f "$c"; then has_limine=1; break; fi
done
if [[ -z "$has_limine" ]]; then
  ok "No Limine config found; skipping clean-boot (bootloader not supported)."
  return 0 2>/dev/null || exit 0
fi

answer="${RAT_CLEAN_BOOT:-}"
if [[ -z "$answer" ]]; then
  if [[ -r /dev/tty ]]; then
    printf 'Quiet the boot for a clean look (suppress scrolling text)? [y/N] ' > /dev/tty
    read -r answer < /dev/tty || answer=""
  else
    warn "No TTY to prompt on; skipping clean-boot. Set RAT_CLEAN_BOOT=yes to force."
    answer="no"
  fi
fi

case "${answer,,}" in
  y|yes)
    "$RAT_DIR/bin/clean-boot"
    ok "Clean boot applied. Undo any time with: clean-boot --revert"
    ;;
  *)
    ok "Skipping clean-boot (normal verbose boot)."
    ;;
esac
