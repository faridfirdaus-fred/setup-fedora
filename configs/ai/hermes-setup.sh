#!/usr/bin/env bash
# hermes-setup.sh — Configure Hermes Agent to route through local OmniRoute proxy
# using `hermes config set` (never hand-editing ~/.hermes/config.yaml).
set -euo pipefail

HERMES_BIN="${HERMES_BIN:-$(command -v hermes || echo "$HOME/.local/bin/hermes")}"
if [[ ! -x "$HERMES_BIN" ]]; then
  echo "Error: hermes binary tidak ditemukan ($HERMES_BIN)." >&2
  exit 1
fi

OMNIROUTE_BASE_URL="${OMNIROUTE_BASE_URL:-http://localhost:20128/v1}"
HERMES_HOME_DIR="${HERMES_HOME:-$HOME/.hermes}"

set_cfg() {
  local key="$1"
  local val="$2"
  "$HERMES_BIN" config set "$key" "$val" >/dev/null 2>&1 \
    || "$HERMES_BIN" config set --force "$key" "$val" >/dev/null
}

echo "==> Mengatur provider OmniRoute di Hermes Agent ($OMNIROUTE_BASE_URL)"

# Custom provider entry (non-legacy providers.omniroute schema)
set_cfg providers.omniroute.name omniroute
set_cfg providers.omniroute.api "$OMNIROUTE_BASE_URL"
set_cfg providers.omniroute.default_model daily
set_cfg providers.omniroute.key_env OMNIROUTE_API_KEY
set_cfg providers.omniroute.models.daily '{}'
set_cfg providers.omniroute.models.planner '{}'
set_cfg providers.omniroute.models.quick '{}'

# Active default model + agent behavior
set_cfg model.default daily
set_cfg model.provider omniroute
set_cfg model.base_url "$OMNIROUTE_BASE_URL"
set_cfg agent.reasoning_effort xhigh
set_cfg delegation.provider omniroute
set_cfg delegation.model daily

# Auxiliary model routing: lightweight tasks -> quick, heavy reasoning/vision -> daily
for aux_quick in \
  compression \
  skills_hub \
  approval \
  mcp \
  title_generation \
  memory_query_rewrite \
  tts_audio_tags \
  triage_specifier \
  profile_describer \
  monitor; do
  set_cfg "auxiliary.${aux_quick}.provider" omniroute
  set_cfg "auxiliary.${aux_quick}.model" quick
done

for aux_daily in \
  vision \
  review \
  kanban_decomposer \
  goal_judge \
  curator \
  background_review \
  moa_reference \
  moa_aggregator; do
  set_cfg "auxiliary.${aux_daily}.provider" omniroute
  set_cfg "auxiliary.${aux_daily}.model" daily
done

# Seed OMNIROUTE_API_KEY into ~/.hermes/.env only if provided via env var (never echoed)
mkdir -p "$HERMES_HOME_DIR"
env_file="$HERMES_HOME_DIR/.env"
touch "$env_file"
chmod 600 "$env_file"

if [[ -n "${OMNIROUTE_API_KEY:-}" ]]; then
  if grep -qE '^OMNIROUTE_API_KEY=' "$env_file"; then
    python3 - "$env_file" <<'PY'
import os, pathlib, sys
p = pathlib.Path(sys.argv[1])
key = os.environ["OMNIROUTE_API_KEY"]
lines = p.read_text().splitlines()
out = [f"OMNIROUTE_API_KEY={key}" if l.startswith("OMNIROUTE_API_KEY=") else l for l in lines]
p.write_text("\n".join(out) + "\n")
PY
  else
    printf 'OMNIROUTE_API_KEY=%s\n' "$OMNIROUTE_API_KEY" >> "$env_file"
  fi
  echo "[ok] OMNIROUTE_API_KEY ditulis ke $env_file (mode 600)."
elif ! grep -qE '^OMNIROUTE_API_KEY=' "$env_file"; then
  echo "[!] Tambahkan OMNIROUTE_API_KEY=<token-dari-omniroute> ke $env_file sebelum menjalankan hermes."
fi

echo "[ok] Konfigurasi Hermes Agent selesai. Verifikasi dengan: hermes doctor"
