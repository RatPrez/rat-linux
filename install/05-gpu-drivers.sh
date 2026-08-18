#!/usr/bin/env bash
# Detects the GPU vendor(s) present (AMD / Intel / Nvidia, via lspci) and
# installs the matching driver stack for each. Hybrid setups (e.g. an Intel +
# Nvidia Optimus laptop) get both stacks installed.
#
# Nvidia additionally needs a choice between its open-source and proprietary
# kernel modules — prompted once and remembered in
# ~/.local/state/rat-linux/nvidia-driver (set RAT_NVIDIA_DRIVER=open|proprietary
# to skip the prompt). Re-runs (e.g. `rat update`) reuse that choice instead of
# asking again; use `rat nvidia` to change it later.

# shellcheck source=../lib/nvidia.sh
source "$RAT_DIR/lib/nvidia.sh"

mapfile -t gpus < <(detect_gpu_vendors)

if [[ ${#gpus[@]} -eq 0 ]]; then
  warn "No AMD/Intel/Nvidia GPU detected via lspci; installing generic mesa only."
  pac_install <<<"mesa"
fi

for vendor in "${gpus[@]}"; do
  case "$vendor" in
    amd)
      log "AMD GPU detected — installing mesa/Vulkan (RADV) stack"
      pac_install < <(read_list "$RAT_DIR/packages/gpu-amd.txt")
      ;;
    intel)
      log "Intel GPU detected — installing mesa/Vulkan (ANV) stack"
      pac_install < <(read_list "$RAT_DIR/packages/gpu-intel.txt")
      ;;
    nvidia)
      log "Nvidia GPU detected"
      variant="$(current_nvidia_variant)"
      [[ -n "$variant" ]] || variant="$(prompt_nvidia_variant)"
      install_nvidia_driver "$variant"
      ;;
  esac
done

ok "GPU driver setup complete (${gpus[*]:-none detected})"
