#!/usr/bin/env bash
# 10-ai-stack.sh — Configure OmniRoute (loopback + systemd user service),
# Hermes Agent (official installer + OmniRoute routing), and Claude Code settings.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

load_nvm

# ------------------------------------------------------------
# 1. OmniRoute local AI proxy (loopback 127.0.0.1 + systemd user)
# ------------------------------------------------------------
log "Setup OmniRoute local proxy (127.0.0.1:20128 + systemd user service)"

if ! command -v omniroute >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    npm install -g omniroute || warn "Gagal install omniroute via npm"
  else
    warn "npm tidak ditemukan; jalankan step 'shell' terlebih dahulu."
  fi
fi

mkdir -p "$HOME/.omniroute" "$HOME/.config/systemd/user"
chmod 700 "$HOME/.omniroute"

omni_env="$HOME/.omniroute/.env"
touch "$omni_env"
chmod 600 "$omni_env"
if ! grep -qE '^OMNIROUTE_SERVER_HOST=' "$omni_env"; then
  printf '\nOMNIROUTE_SERVER_HOST=127.0.0.1\n' >> "$omni_env"
  ok "OMNIROUTE_SERVER_HOST=127.0.0.1 ditambahkan ke $omni_env"
else
  ok "OMNIROUTE_SERVER_HOST sudah diatur di $omni_env"
fi

node_bin="$(resolve_node_bin || true)"
omni_bin="$(command -v omniroute || true)"

if [[ -n "$node_bin" && -n "$omni_bin" ]]; then
  omni_real="$(readlink -f "$omni_bin" 2>/dev/null || echo "$omni_bin")"
  node_dir="$(dirname "$node_bin")"
  unit_dest="$HOME/.config/systemd/user/omniroute.service"

  sed \
    -e "s|__NODE_BIN__|${node_bin}|g" \
    -e "s|__OMNIROUTE_BIN__|${omni_real}|g" \
    -e "s|__NODE_DIR__|${node_dir}|g" \
    "$REPO_ROOT/configs/systemd/user/omniroute.service.template" > "$unit_dest"
  chmod 0644 "$unit_dest"

  if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable omniroute.service
    if ! ss -tln 2>/dev/null | grep -q ':20128 '; then
      systemctl --user start omniroute.service || warn "Gagal start omniroute.service (cek: journalctl --user -u omniroute.service)"
    else
      ok "Port 20128 sudah aktif (skip restart agar sesi aktif tidak terputus)."
    fi
    loginctl enable-linger "$USER" 2>/dev/null || true
    ok "omniroute.service terpasang & enabled."
  else
    warn "systemd user bus tidak aktif; aktifkan manual: systemctl --user enable --now omniroute.service"
  fi
else
  warn "node atau omniroute belum ditemukan — lewati pembuatan omniroute.service."
fi

# ------------------------------------------------------------
# 2. Hermes Agent
# ------------------------------------------------------------
log "Setup Hermes Agent"
if ! command -v hermes >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/hermes" ]]; then
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash \
    || warn "Gagal install Hermes Agent"
else
  ok "Hermes Agent sudah terpasang."
fi

export PATH="$HOME/.local/bin:$PATH"
if command -v hermes >/dev/null 2>&1; then
  bash "$REPO_ROOT/configs/ai/hermes-setup.sh" || warn "Gagal apply konfigurasi Hermes"
else
  warn "hermes binary belum tersedia; jalankan manual: bash configs/ai/hermes-setup.sh"
fi

# ------------------------------------------------------------
# 3. Claude Code (~/.claude/settings.json routed to OmniRoute)
# ------------------------------------------------------------
log "Setup Claude Code (~/.claude/settings.json)"
mkdir -p "$HOME/.claude"
claude_settings="$HOME/.claude/settings.json"

if [[ ! -f "$claude_settings" || "${FORCE_CLAUDE_CONFIG:-0}" -eq 1 ]]; then
  cp "$REPO_ROOT/configs/ai/claude-settings.json.template" "$claude_settings"
  chmod 600 "$claude_settings"
  if [[ -n "${OMNIROUTE_API_KEY:-}" ]]; then
    python3 - "$claude_settings" <<'PY'
import json, os, pathlib, sys
p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text())
data.setdefault("env", {})["ANTHROPIC_AUTH_TOKEN"] = os.environ["OMNIROUTE_API_KEY"]
p.write_text(json.dumps(data, indent=2) + "\n")
PY
    ok "Claude Code settings ditulis dengan OMNIROUTE_API_KEY dari environment."
  else
    warn "Template Claude Code ditulis ke $claude_settings."
    warn "Ganti __OMNIROUTE_API_KEY__ dengan API key dari dashboard OmniRoute (http://localhost:20128)."
  fi
else
  ok "$claude_settings sudah ada (set FORCE_CLAUDE_CONFIG=1 untuk menimpa dengan template)."
fi

# ------------------------------------------------------------
# 4. Ringkasan pasca-install AI Stack
# ------------------------------------------------------------
log "Langkah lanjutan AI Stack (sekali jalan di mesin baru):"
warn "1. Buka dashboard OmniRoute: http://localhost:20128 -> login/hubungkan provider upstream & buat API key."
warn "2. Buat combos (daily, planner, quick) mengacu pada: $REPO_ROOT/configs/ai/omniroute-combos.json"
warn "3. Masukkan API key OmniRoute ke:"
warn "   - ~/.hermes/.env          (OMNIROUTE_API_KEY=<key>)"
warn "   - ~/.claude/settings.json (env.ANTHROPIC_AUTH_TOKEN)"
warn "4. Verifikasi:"
warn "   - ss -tlnp | grep 20128   (pastikan bind 127.0.0.1:20128, bukan 0.0.0.0)"
warn "   - hermes doctor"
warn "   - claude -p 'Reply with just OK' --model sonnet --max-turns 1 --no-session-persistence"
ok "AI Stack setup selesai."
