#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="mono-minimal"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/${THEME_NAME}"
DEST_DIR="/boot/grub2/themes/${THEME_NAME}"
GRUB_DEFAULT="/etc/default/grub"
GRUB_CFG="/boot/grub2/grub.cfg"

if [[ ${EUID} -ne 0 ]]; then
    echo "Error: Please run as root (sudo $0)"
    exit 1
fi

if [[ ! -f "${SRC_DIR}/theme.txt" ]]; then
    echo "Error: Theme not found at ${SRC_DIR}/theme.txt"
    exit 1
fi

echo "==> Installing GRUB theme '${THEME_NAME}' to ${DEST_DIR}"
mkdir -p /boot/grub2/themes
rm -rf "${DEST_DIR}"
cp -a "${SRC_DIR}" "${DEST_DIR}"
chown -R root:root "${DEST_DIR}"
find "${DEST_DIR}" -type d -exec chmod 755 {} +
find "${DEST_DIR}" -type f -exec chmod 644 {} +

if command -v restorecon >/dev/null 2>&1; then
    restorecon -RF "${DEST_DIR}" 2>/dev/null || true
fi

# Backup /etc/default/grub
BACKUP="${GRUB_DEFAULT}.bak.$(date +%Y%m%d_%H%M%S)"
cp -a "${GRUB_DEFAULT}" "${BACKUP}"
echo "==> Backed up ${GRUB_DEFAULT} -> ${BACKUP}"

if [[ ! -f "${GRUB_DEFAULT}.mono-minimal.orig" ]]; then
    cp -a "${GRUB_DEFAULT}" "${GRUB_DEFAULT}.mono-minimal.orig"
fi

set_grub_var() {
    local key="$1"
    local val="$2"
    if grep -qE "^[#[:space:]]*${key}=" "${GRUB_DEFAULT}"; then
        sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=\"${val}\"|" "${GRUB_DEFAULT}"
    else
        printf '\n%s="%s"\n' "${key}" "${val}" >> "${GRUB_DEFAULT}"
    fi
}

echo "==> Configuring ${GRUB_DEFAULT}"
set_grub_var "GRUB_TERMINAL_OUTPUT" "gfxterm"
set_grub_var "GRUB_GFXMODE" "1920x1080,auto"
set_grub_var "GRUB_GFXPAYLOAD_LINUX" "keep"
set_grub_var "GRUB_THEME" "${DEST_DIR}/theme.txt"

echo "==> Regenerating ${GRUB_CFG}"
grub2-mkconfig -o "${GRUB_CFG}"

echo ""
echo "Done! Theme '${THEME_NAME}' is installed and active."
echo "Reboot to see the new black & white minimalist GRUB UI."
echo "To revert anytime: sudo ${SCRIPT_DIR}/uninstall.sh"
