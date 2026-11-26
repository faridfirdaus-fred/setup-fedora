#!/usr/bin/env bash
# Shared helpers for setup-fedora modular scripts

if [[ -n "${SETUP_FEDORA_COMMON_LOADED:-}" ]]; then
  return 0
fi
SETUP_FEDORA_COMMON_LOADED=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; }

require_non_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    err "Jangan jalankan sebagai root. Script ini memanggil sudo sendiri saat perlu."
    exit 1
  fi
}

confirm() {
  local prompt="$1"
  local default="${2:-y}"
  if [[ "${AUTO_YES:-0}" -eq 1 ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    [[ "$default" == "y" ]]
    return $?
  fi
  local yn="[Y/n]"
  [[ "$default" == "n" ]] && yn="[y/N]"
  local ans=""
  read -r -p "$prompt $yn " ans || true
  ans="${ans:-$default}"
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

append_block_once() {
  local file="$1"
  local marker="$2"
  local content="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf '\n%s\n' "$content" >> "$file"
  fi
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
}

resolve_node_bin() {
  load_nvm
  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi
  if [[ -d "$HOME/.nvm/versions/node" ]]; then
    local latest
    latest="$(find "$HOME/.nvm/versions/node" -maxdepth 3 -path '*/bin/node' -type f 2>/dev/null | sort -V | tail -n 1 || true)"
    if [[ -n "$latest" ]]; then
      echo "$latest"
      return 0
    fi
  fi
  return 1
}
