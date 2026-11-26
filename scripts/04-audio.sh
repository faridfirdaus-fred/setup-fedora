#!/usr/bin/env bash
# 04-audio.sh — PipeWire hi-res audio configuration (96 kHz default, multi-rate allowed).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

log "Konfigurasi PipeWire hi-res audio (96 kHz default)"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
install -m 0644 \
  "$REPO_ROOT/configs/pipewire/10-hires.conf" \
  "$HOME/.config/pipewire/pipewire.conf.d/10-hires.conf"

if systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null; then
  ok "PipeWire direstart dengan konfigurasi hi-res."
else
  warn "Restart PipeWire manual nanti: systemctl --user restart pipewire pipewire-pulse wireplumber"
fi
warn "Jika DAC/IEM tidak mendukung 96 kHz, ubah default.clock.rate di ~/.config/pipewire/pipewire.conf.d/10-hires.conf."
