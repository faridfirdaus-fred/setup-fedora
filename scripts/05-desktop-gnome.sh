#!/usr/bin/env bash
# 05-desktop-gnome.sh — Orchis GTK theme, Colloid icons, Geist fonts, GNOME dconf/gsettings,
# GNOME Shell extensions + settings, true-zero brightness helper, and custom keybindings.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

log "Install Orchis GTK theme & Colloid icon theme"
mkdir -p "$HOME/.themes" "$HOME/.icons"
tmp_themes="$(mktemp -d)"
trap 'rm -rf "$tmp_themes"' EXIT

if [[ ! -d "$HOME/.themes/Orchis-Dark" || "${FORCE_THEMES:-0}" -eq 1 ]]; then
  if git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git "$tmp_themes/orchis"; then
    "$tmp_themes/orchis/install.sh" -d "$HOME/.themes" || warn "Gagal install Orchis theme"
  else
    warn "Gagal clone Orchis-theme"
  fi
else
  ok "Orchis theme sudah terpasang."
fi

if [[ ! -d "$HOME/.icons/Colloid" || "${FORCE_THEMES:-0}" -eq 1 ]]; then
  if git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git "$tmp_themes/colloid"; then
    "$tmp_themes/colloid/install.sh" -d "$HOME/.icons" || warn "Gagal install Colloid icon theme"
  else
    warn "Gagal clone Colloid-icon-theme"
  fi
else
  ok "Colloid icon theme sudah terpasang."
fi

log "Install true-zero brightness helper (~/.local/bin/brightness-zero)"
mkdir -p "$HOME/.local/bin"
install -m 0755 "$REPO_ROOT/bin/brightness-zero" "$HOME/.local/bin/brightness-zero"
ok "Terpasang: $HOME/.local/bin/brightness-zero"

if ! command -v gsettings >/dev/null 2>&1 || [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  warn "Sesi GNOME/D-Bus tidak terdeteksi — lewati gsettings & GNOME extensions."
  warn "Jalankan ulang step ini dari dalam sesi desktop GNOME: ./install.sh --only desktop"
  exit 0
fi

log "Apply GNOME desktop appearance, fonts, power & peripherals"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface icon-theme 'Colloid' || true
gsettings set org.gnome.desktop.interface font-name 'Geist 11' || true
gsettings set org.gnome.desktop.interface document-font-name 'Geist 12' || true
gsettings set org.gnome.desktop.interface monospace-font-name 'Geist Mono 11' || true
gsettings set org.gnome.desktop.interface text-scaling-factor 1.1 || true
gsettings set org.gnome.desktop.interface show-battery-percentage true || true
gsettings set org.gnome.desktop.interface enable-animations true || true
gsettings set org.gnome.desktop.interface overlay-scrolling true || true

gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' || true
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' || true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas' || true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true || true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true || true

gsettings set org.gnome.shell favorite-apps \
  "['brave-browser.desktop', 'com.discordapp.Discord.desktop', 'org.gnome.Nautilus.desktop', 'orca.desktop', 'org.gnome.Software.desktop', 'com.spotify.Client.desktop', 'org.gnome.Ptyxis.desktop']" \
  || true

log "Konfigurasi GNOME custom keybindings (Terminal, Brightness-to-0, Keyboard Backlight)"
# Kosongkan binding built-in brightness agar gsd-media-keys bisa mengambil alih ke brightness-zero
gsettings set org.gnome.shell.keybindings screen-brightness-down "[]" || true
gsettings set org.gnome.shell.keybindings screen-brightness-up "[]" || true

BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['${BASE}/custom0/', '${BASE}/custom1/', '${BASE}/custom2/', '${BASE}/custom3/', '${BASE}/custom4/', '${BASE}/custom5/']"

set_kb() {
  local idx="$1" name="$2" cmd="$3" bind="$4"
  local schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${BASE}/custom${idx}/"
  gsettings set "$schema" name "$name"
  gsettings set "$schema" command "$cmd"
  gsettings set "$schema" binding "$bind"
}

set_kb 0 "Open Terminal" "ptyxis --new-window" "<Super>t"
set_kb 1 "Brightness Down (to 0)" "${HOME}/.local/bin/brightness-zero down" "XF86MonBrightnessDown"
set_kb 2 "Brightness Up (from 0)" "${HOME}/.local/bin/brightness-zero up" "XF86MonBrightnessUp"
set_kb 3 "Backlight Toggle" "/usr/local/bin/kbdlight toggle" "<Super>F4"
set_kb 4 "Backlight Up" "/usr/local/bin/kbdlight up" "<Super>F2"
set_kb 5 "Backlight Down" "/usr/local/bin/kbdlight down" "<Super>F3"

log "Install & enable GNOME Shell extensions"
if command -v gnome-extensions >/dev/null 2>&1 && command -v gnome-shell >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  shell_ver="$(gnome-shell --version | awk '{print $3}')"
  shell_major="${shell_ver%%.*}"
  ext_tmp="$(mktemp -d)"

  while IFS= read -r uuid; do
    uuid="${uuid%%#*}"
    uuid="$(echo "$uuid" | xargs)"
    [[ -n "$uuid" ]] || continue

    if gnome-extensions info "$uuid" >/dev/null 2>&1; then
      ok "Extension sudah terpasang: $uuid"
    else
      info_json="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${shell_major}" 2>/dev/null || true)"
      dl_path="$(printf '%s' "$info_json" | jq -r '.download_url // empty' 2>/dev/null || true)"
      if [[ -n "$dl_path" ]]; then
        zip_file="${ext_tmp}/${uuid}.zip"
        if curl -fsSL "https://extensions.gnome.org${dl_path}" -o "$zip_file"; then
          gnome-extensions install --force "$zip_file" && ok "Terpasang: $uuid" \
            || warn "Gagal install extension: $uuid"
        else
          warn "Gagal download extension: $uuid"
        fi
      else
        warn "Tidak menemukan rilis kompatibel GNOME ${shell_major} untuk: $uuid (install manual via Extension Manager)"
      fi
    fi
  done < "$REPO_ROOT/configs/gnome/extensions.txt"

  rm -rf "$ext_tmp"

  # Load extension settings (blur-my-shell, simple-taskbar, tilingshell, system-monitor)
  if command -v dconf >/dev/null 2>&1 && [[ -f "$REPO_ROOT/configs/gnome/extensions.dconf" ]]; then
    log "Load konfigurasi dconf untuk GNOME extensions"
    dconf load /org/gnome/shell/extensions/ < "$REPO_ROOT/configs/gnome/extensions.dconf" \
      || warn "Gagal load extensions.dconf"
  fi

  # Enable semua extension yang terdaftar + background-logo bawaan Fedora
  while IFS= read -r uuid; do
    uuid="${uuid%%#*}"
    uuid="$(echo "$uuid" | xargs)"
    [[ -n "$uuid" ]] || continue
    gnome-extensions enable "$uuid" 2>/dev/null || warn "Belum bisa enable (mungkin butuh logout/login): $uuid"
  done < "$REPO_ROOT/configs/gnome/extensions.txt"
  gnome-extensions enable "background-logo@fedorahosted.org" 2>/dev/null || true
else
  warn "gnome-extensions / gnome-shell / jq tidak tersedia; install extensions manual via Extension Manager."
fi

ok "Desktop GNOME, tema, shortcut & extensions selesai."
warn "Logout/login ulang agar semua GNOME extension yang baru diinstall aktif penuh."
