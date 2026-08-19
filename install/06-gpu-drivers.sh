#!/usr/bin/env bash
# Detects the GPU vendor(s) present (AMD / Intel / Nvidia, via lspci) and
# installs the matching driver stack for each. Hybrid setups get both.
#

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
      log "AMD GPU detected, installing mesa/Vulkan (RADV) stack"
      pac_install < <(read_list "$RAT_DIR/packages/gpu-amd.txt")
      ;;
    intel)
      log "Intel GPU detected, installing mesa/Vulkan (ANV) stack"
      pac_install < <(read_list "$RAT_DIR/packages/gpu-intel.txt")
      ;;
    nvidia)
      log "Nvidia GPU detected"
      install_nvidia_driver
      ;;
  esac
done

ok "GPU driver setup complete (${gpus[*]:-none detected})"
