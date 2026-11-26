#!/usr/bin/env bash
# 07-laptop-maintenance.sh — Install weekly user & system laptop maintenance scripts and timers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

log "Install script & systemd user timer: laptop-maintenance"
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.config/laptop-maintenance"

install -m 0755 "$REPO_ROOT/bin/laptop-maintenance" "$HOME/.local/bin/laptop-maintenance"
install -m 0644 \
  "$REPO_ROOT/configs/systemd/user/laptop-maintenance.service" \
  "$HOME/.config/systemd/user/laptop-maintenance.service"
install -m 0644 \
  "$REPO_ROOT/configs/systemd/user/laptop-maintenance.timer" \
  "$HOME/.config/systemd/user/laptop-maintenance.timer"

# Simpan salinan referensi sistem di ~/.config/laptop-maintenance juga
install -m 0755 "$REPO_ROOT/bin/laptop-maintenance-system" "$HOME/.config/laptop-maintenance/laptop-maintenance-system"
install -m 0644 \
  "$REPO_ROOT/configs/systemd/system/laptop-maintenance-system.service" \
  "$HOME/.config/laptop-maintenance/laptop-maintenance-system.service"
install -m 0644 \
  "$REPO_ROOT/configs/systemd/system/laptop-maintenance-system.timer" \
  "$HOME/.config/laptop-maintenance/laptop-maintenance-system.timer"

if systemctl --user daemon-reload 2>/dev/null; then
  systemctl --user enable --now laptop-maintenance.timer
  ok "User timer aktif: laptop-maintenance.timer (Minggu 09:00)"
else
  warn "systemd user bus tidak aktif; aktifkan manual nanti: systemctl --user enable --now laptop-maintenance.timer"
fi

log "Install script & systemd system timer: laptop-maintenance-system"
sudo install -o root -g root -m 0755 \
  "$REPO_ROOT/bin/laptop-maintenance-system" \
  /usr/local/sbin/laptop-maintenance-system
sudo install -o root -g root -m 0644 \
  "$REPO_ROOT/configs/systemd/system/laptop-maintenance-system.service" \
  /etc/systemd/system/laptop-maintenance-system.service
sudo install -o root -g root -m 0644 \
  "$REPO_ROOT/configs/systemd/system/laptop-maintenance-system.timer" \
  /etc/systemd/system/laptop-maintenance-system.timer

sudo systemctl daemon-reload
sudo systemctl enable --now laptop-maintenance-system.timer
ok "System timer aktif: laptop-maintenance-system.timer (Minggu 09:10)"

log "Ringkasan status pemeliharaan laptop"
"$HOME/.local/bin/laptop-maintenance" --status || true
