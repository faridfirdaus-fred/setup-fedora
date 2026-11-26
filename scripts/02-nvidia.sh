#!/usr/bin/env bash
# 02-nvidia.sh — Install proprietary NVIDIA driver + CUDA via RPM Fusion akmod-nvidia.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

if [[ "${FORCE_NVIDIA:-0}" -ne 1 ]]; then
  if command -v lspci >/dev/null 2>&1 && ! lspci | grep -qi 'nvidia'; then
    warn "GPU NVIDIA tidak terdeteksi via lspci. Lewati step NVIDIA (set FORCE_NVIDIA=1 untuk paksa)."
    exit 0
  fi
fi

log "Install driver NVIDIA (akmod-nvidia + CUDA)"
sudo dnf install -y kernel-devel kernel-headers akmod-nvidia xorg-x11-drv-nvidia-cuda \
  || { warn "Gagal install driver NVIDIA"; exit 1; }

warn "akmod membangun kernel module NVIDIA di background. Tunggu beberapa menit lalu REBOOT."
warn "Cek build status: modinfo -F version nvidia"
warn "Jika Secure Boot aktif, enroll MOK (layar biru) saat reboot pertama."
ok "Instalasi paket NVIDIA selesai."
