#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="mono-minimal"
DEST_DIR="/boot/grub2/themes/${THEME_NAME}"
GRUB_DEFAULT="/etc/default/grub"
ORIG_BACKUP="${GRUB_DEFAULT}.mono-minimal.orig"
GRUB_CFG="/boot/grub2/grub.cfg"

if [[ ${EUID} -ne 0 ]]; then
    echo "Error: Please run as root (sudo $0)"
    exit 1
fi

echo "==> Removing ${DEST_DIR}"
rm -rf "${DEST_DIR}"

if [[ -f "${ORIG_BACKUP}" ]]; then
    echo "==> Restoring original ${GRUB_DEFAULT} from ${ORIG_BACKUP}"
    cp -a "${ORIG_BACKUP}" "${GRUB_DEFAULT}"
    rm -f "${ORIG_BACKUP}"
else
    echo "==> Reverting theme settings in ${GRUB_DEFAULT}"
    sed -i -E '/^GRUB_THEME=/d' "${GRUB_DEFAULT}"
    sed -i -E '/^GRUB_GFXMODE=/d' "${GRUB_DEFAULT}"
    sed -i -E '/^GRUB_GFXPAYLOAD_LINUX=/d' "${GRUB_DEFAULT}"
    sed -i -E 's|^GRUB_TERMINAL_OUTPUT="gfxterm"|GRUB_TERMINAL_OUTPUT="console"|' "${GRUB_DEFAULT}"
fi

echo "==> Regenerating ${GRUB_CFG}"
grub2-mkconfig -o "${GRUB_CFG}"

echo "Done! Restored default Fedora GRUB configuration."
