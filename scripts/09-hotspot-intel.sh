#!/usr/bin/env bash
# 09-hotspot-intel.sh — Enable 5 GHz Wi-Fi AP hotspot on Intel AX200/AX201 via patched iwlmvm (LAR disabled).
# Repo: https://github.com/faridfirdaus-fred/hotspot-linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

HOTSPOT_REPO_URL="${HOTSPOT_REPO_URL:-https://github.com/faridfirdaus-fred/hotspot-linux.git}"
HOTSPOT_DIR="${HOTSPOT_DIR:-$HOME/hotspot-linux}"
HOTSPOT_COUNTRY="${HOTSPOT_COUNTRY:-ID}"

if [[ "${FORCE_HOTSPOT:-0}" -ne 1 ]]; then
  if command -v lspci >/dev/null 2>&1 && ! lspci | grep -qiE 'intel.*(wi-?fi|wireless|centrino)'; then
    warn "Adapter Intel Wi-Fi tidak terdeteksi. Lewati hotspot-linux (set FORCE_HOTSPOT=1 untuk paksa)."
    exit 0
  fi
fi

if command -v mokutil >/dev/null 2>&1; then
  if mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'; then
    warn "Secure Boot aktif — modul override iwlmvm unsigned tidak bisa dimuat saat lockdown."
    warn "Nonaktifkan Secure Boot di BIOS lalu jalankan ulang: ./install.sh --only hotspot"
    exit 0
  fi
fi

log "Clone / update repo hotspot-linux -> $HOTSPOT_DIR"
if [[ -d "$HOTSPOT_DIR/.git" ]]; then
  git -C "$HOTSPOT_DIR" pull --ff-only || warn "Gagal git pull $HOTSPOT_DIR, lanjut pakai checkout lokal."
else
  git clone "$HOTSPOT_REPO_URL" "$HOTSPOT_DIR"
fi

log "Jalankan installer hotspot-linux (country: $HOTSPOT_COUNTRY)"
install_args=(--country "$HOTSPOT_COUNTRY")
[[ "${FORCE_HOTSPOT:-0}" -eq 1 ]] && install_args+=(--force)
sudo bash "$HOTSPOT_DIR/install.sh" "${install_args[@]}"

ok "hotspot-linux selesai dipasang."
warn "Gunakan: hotspot-setting (atur SSID/password), hotspot-on, hotspot-off, hotspot-status."
