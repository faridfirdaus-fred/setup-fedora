#!/usr/bin/env bash
# 06-grub-theme.sh — Install bundled 'mono-minimal' black & white GRUB2 boot theme.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

GRUB_DIR="$REPO_ROOT/grub/mono-minimal"

if [[ ! -x "$GRUB_DIR/install.sh" ]]; then
  err "Installer GRUB theme tidak ditemukan di $GRUB_DIR/install.sh"
  exit 1
fi

log "Install GRUB2 theme 'mono-minimal' (Geist font, black & white minimalist)"
sudo bash "$GRUB_DIR/install.sh"
ok "GRUB theme 'mono-minimal' terpasang."
warn "Untuk revert ke GRUB default Fedora kapan saja: sudo $GRUB_DIR/uninstall.sh"
