#!/usr/bin/env bash
# setup-fedora — Modular, idempotent Fedora Workstation environment setup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MODULES=(
  "base:01-base-packages.sh:RPM Fusion, Flathub, DNF, Docker CE, Flatpak, Brave, VS Code, Zed, pip"
  "nvidia:02-nvidia.sh:NVIDIA proprietary driver + CUDA (akmod-nvidia, auto-detect GPU)"
  "shell:03-shell-dev.sh:Zsh, Oh My Zsh + plugins, NVM + Node LTS, npm global CLIs"
  "audio:04-audio.sh:PipeWire hi-res 96 kHz audio config"
  "desktop:05-desktop-gnome.sh:Orchis GTK, Colloid icons, Geist fonts, GNOME dconf, extensions, brightness-zero, keybindings"
  "grub:06-grub-theme.sh:GRUB2 mono-minimal black & white boot theme"
  "maintenance:07-laptop-maintenance.sh:Weekly user + system laptop-maintenance scripts & systemd timers"
  "clevo:08-clevo-backlight.sh:Clevo/Axioo keyboard backlight driver + kbdlight/kbdlightd (auto-detect HW)"
  "hotspot:09-hotspot-intel.sh:Intel Wi-Fi 5 GHz AP hotspot via patched iwlmvm (auto-detect Intel + Secure Boot)"
  "ai:10-ai-stack.sh:OmniRoute (127.0.0.1 + systemd), Hermes Agent, Claude Code config templates"
)

ONLY_LIST=""
SKIP_LIST=""
AUTO_YES=0
LIST_ONLY=0

usage() {
  cat <<'EOF'
Penggunaan: ./install.sh [OPSI]

Opsi:
  --list              Tampilkan semua modul setup yang tersedia
  --only m1,m2,...    Jalankan hanya modul tertentu (pisahkan dengan koma)
  --skip m1,m2,...    Lewati modul tertentu (pisahkan dengan koma)
  -y, --yes           Non-interaktif (otomatis setuju)
  -h, --help          Tampilkan bantuan ini

Contoh:
  ./install.sh                              # Jalankan semua modul (full fresh install)
  ./install.sh --skip nvidia,clevo,hotspot  # Setup Fedora generik tanpa driver hardware khusus
  ./install.sh --only desktop,grub,ai       # Terapkan ulang desktop GNOME, GRUB theme, & AI stack
  OMNIROUTE_API_KEY=sk-... ./install.sh --only ai
EOF
}

list_modules() {
  printf '%-14s %-28s %s\n' "MODUL" "SCRIPT" "DESKRIPSI"
  printf '%-14s %-28s %s\n' "-----" "------" "---------"
  local entry name script desc
  for entry in "${MODULES[@]}"; do
    IFS=':' read -r name script desc <<<"$entry"
    printf '%-14s %-28s %s\n' "$name" "scripts/$script" "$desc"
  done
}

in_csv() {
  local needle="$1"
  local haystack="$2"
  [[ -z "$haystack" ]] && return 1
  local item
  IFS=',' read -ra items <<<"$haystack"
  for item in "${items[@]}"; do
    [[ "${item// /}" == "$needle" ]] && return 0
  done
  return 1
}

validate_csv() {
  local csv="$1"
  [[ -z "$csv" ]] && return 0
  local item entry name found
  IFS=',' read -ra items <<<"$csv"
  for item in "${items[@]}"; do
    item="${item// /}"
    [[ -n "$item" ]] || continue
    found=0
    for entry in "${MODULES[@]}"; do
      IFS=':' read -r name _ _ <<<"$entry"
      if [[ "$name" == "$item" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      err "Modul tidak dikenal: '$item'. Lihat daftar dengan: ./install.sh --list"
      exit 2
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST_ONLY=1; shift ;;
    --only)
      [[ $# -ge 2 ]] || { err "--only butuh daftar modul"; exit 2; }
      ONLY_LIST="$2"; shift 2 ;;
    --skip)
      [[ $# -ge 2 ]] || { err "--skip butuh daftar modul"; exit 2; }
      SKIP_LIST="$2"; shift 2 ;;
    -y|--yes) AUTO_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Opsi tidak dikenal: $1"; usage >&2; exit 2 ;;
  esac
done

if [[ "$LIST_ONLY" -eq 1 ]]; then
  list_modules
  exit 0
fi

require_non_root
validate_csv "$ONLY_LIST"
validate_csv "$SKIP_LIST"
export AUTO_YES

FAILED_MODULES=()
RAN_COUNT=0

for entry in "${MODULES[@]}"; do
  IFS=':' read -r name script desc <<<"$entry"

  if [[ -n "$ONLY_LIST" ]] && ! in_csv "$name" "$ONLY_LIST"; then
    continue
  fi
  if [[ -n "$SKIP_LIST" ]] && in_csv "$name" "$SKIP_LIST"; then
    warn "Skip modul: $name"
    continue
  fi

  RAN_COUNT=$((RAN_COUNT + 1))
  log "[$name] $desc"
  if bash "$SCRIPT_DIR/scripts/$script"; then
    ok "Modul '$name' selesai."
  else
    err "Modul '$name' gagal (lanjut ke modul berikutnya)."
    FAILED_MODULES+=("$name")
  fi
done

log "Catatan aplikasi custom (install manual bila diperlukan):"
warn "- Orca IDE: unduh AppImage -> simpan ke ~/AppImages/orca.appimage (integrasikan via Gear Lever)."
warn "- Antigravity IDE/CLI: ekstrak ke /opt/antigravity + symlink /usr/local/bin/antigravity; icon hicolor di /usr/share/icons/hicolor/512x512/apps/antigravity.png."
warn "- EasyEffects: buka aplikasi dan import preset AutoEQ untuk model IEM/headphone yang dipakai."

echo ""
if [[ ${#FAILED_MODULES[@]} -eq 0 ]]; then
  ok "Semua ${RAN_COUNT} modul selesai tanpa error."
else
  warn "Selesai dengan modul gagal: ${FAILED_MODULES[*]}"
  exit 1
fi

warn "Reboot disarankan agar driver NVIDIA, GRUB theme, default shell Zsh, grup docker/wireshark, dan GNOME extensions aktif penuh."
