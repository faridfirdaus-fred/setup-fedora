#!/usr/bin/env bash
# 03-shell-dev.sh — Zsh, Oh My Zsh + plugins, NVM + Node LTS, global npm CLIs, PATH hygiene.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

NVM_VERSION="${NVM_VERSION:-v0.40.3}"

NPM_GLOBAL_PACKAGES=(
  # AI / coding assistants & proxies
  @anthropic-ai/claude-code
  @openai/codex
  cline
  omniroute
  opencode-ai
  9router
  @kilocode/cli
  @tencent-ai/codebuddy-code

  # JS/TS & code tooling
  @ast-grep/cli
  @nestjs/cli
  corepack
  pnpm
  repomix
)

log "Install Oh My Zsh + plugins (autosuggestions, syntax highlighting)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || warn "Gagal install Oh My Zsh"
else
  ok "Oh My Zsh sudah terpasang."
fi

if [[ ! -f "$HOME/.zshrc" && -f "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ]]; then
  cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
    || warn "Gagal clone zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
    || warn "Gagal clone zsh-syntax-highlighting"
fi

if [[ -f "$HOME/.zshrc" ]]; then
  if grep -qE '^plugins=\(' "$HOME/.zshrc"; then
    sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
  else
    append_block_once "$HOME/.zshrc" "plugins=(git zsh-autosuggestions" \
      'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)'
  fi
fi

log "Install NVM ($NVM_VERSION)"
if [[ ! -d "$HOME/.nvm" ]]; then
  PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
    || warn "Gagal install NVM"
else
  ok "NVM sudah terpasang."
fi

NVM_BLOCK='# NVM (managed by setup-fedora)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

LOCAL_BIN_BLOCK='# User local bin PATH (managed by setup-fedora)
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'

append_block_once "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"' "$NVM_BLOCK"
append_block_once "$HOME/.zshrc" '$HOME/.local/bin' "$LOCAL_BIN_BLOCK"
append_block_once "$HOME/.zprofile" '$HOME/.local/bin' "$LOCAL_BIN_BLOCK"
append_block_once "$HOME/.bashrc" 'export NVM_DIR="$HOME/.nvm"' "$NVM_BLOCK"

load_nvm
if command -v nvm >/dev/null 2>&1; then
  log "Install Node LTS via NVM + npm global CLI"
  nvm install --lts || warn "Gagal install Node LTS via nvm"
  nvm alias default 'lts/*' || warn "Gagal set default Node LTS"
  nvm use default >/dev/null 2>&1 || true

  for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do
    npm install -g "$pkg" || warn "Gagal install (npm): $pkg"
  done
else
  warn "nvm tidak tersedia di sesi ini; lewati npm global."
fi

log "Set zsh sebagai default shell"
if command -v zsh >/dev/null 2>&1; then
  current_shell="$(getent passwd "$USER" | cut -d: -f7 || true)"
  zsh_path="$(command -v zsh)"
  if [[ "$current_shell" != "$zsh_path" ]]; then
    sudo usermod -s "$zsh_path" "$USER" || warn "Gagal ganti default shell ke zsh"
    warn "Default shell baru aktif setelah logout/login ulang."
  else
    ok "Default shell sudah zsh."
  fi
fi

ok "Shell & dev environment selesai."
