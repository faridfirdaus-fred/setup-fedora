#!/usr/bin/env bash
# 08-clevo-backlight.sh — Install Clevo/Axioo single-zone RGB keyboard backlight driver + CLI/daemon.
# Repo: https://github.com/faridfirdaus-fred/clevo-backlight
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

CLEVO_REPO_URL="${CLEVO_REPO_URL:-https://github.com/faridfirdaus-fred/clevo-backlight.git}"
CLEVO_DIR="${CLEVO_DIR:-$HOME/clevo-backlight}"

is_clevo_hw() {
  if compgen -G "/sys/bus/acpi/devices/CLV0001*" >/dev/null 2>&1; then
    return 0
  fi
  local dmi=""
  for f in /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name /sys/class/dmi/id/board_name; do
    [[ -r "$f" ]] && dmi+=" $(cat "$f" 2>/dev/null || true)"
  done
  grep -qiE 'clevo|axioo|pongo|np50|nb50|nh5|nh7|ns5|ns7' <<<"$dmi"
}

if [[ "${FORCE_CLEVO:-0}" -ne 1 ]] && ! is_clevo_hw; then
  warn "Hardware Clevo/Axioo tidak terdeteksi. Lewati clevo-backlight (set FORCE_CLEVO=1 untuk paksa)."
  exit 0
fi

log "Clone / update repo clevo-backlight -> $CLEVO_DIR"
if [[ -d "$CLEVO_DIR/.git" ]]; then
  git -C "$CLEVO_DIR" pull --ff-only || warn "Gagal git pull $CLEVO_DIR, lanjut pakai checkout lokal."
else
  git clone "$CLEVO_REPO_URL" "$CLEVO_DIR"
fi

log "Jalankan installer clevo-backlight (DKMS tuxedo-keyboard + kbdlight + kbdlightd)"
sudo bash "$CLEVO_DIR/install.sh"

ok "clevo-backlight selesai dipasang."
warn "Gunakan: kbdlight {on|off|up|down|toggle|color <hex>|status} atau shortcut Super+F2/F3/F4."
