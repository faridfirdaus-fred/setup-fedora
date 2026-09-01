#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1" >&2; }

if [[ $EUID -eq 0 ]]; then
  echo "Jangan jalankan sebagai root. Script ini pakai sudo sendiri saat perlu." >&2
  exit 1
fi

# ============================================================
# Edit daftar apps di bawah ini sesuai kebutuhan.
# ============================================================

DNF_PACKAGES=(
  nodejs        # nodejs + npm
  gcc-c++       # dibutuhkan native module npm (node-gyp)
  make
  git
  thunderbird
  bleachbit
  mpv
  zsh
)

FLATPAK_PACKAGES=(
  com.spotify.Client
  md.obsidian.Obsidian
  com.discordapp.Discord
  com.protonvpn.www
)

NPM_GLOBAL_PACKAGES=(
  @anthropic-ai/claude-code
  @openai/codex
  cline
  9router
)

# ============================================================

log "Update sistem"
sudo dnf upgrade --refresh -y

log "Enable RPM Fusion (free + nonfree)"
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log "Enable Flathub"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Install paket DNF"
for pkg in "${DNF_PACKAGES[@]}"; do
  sudo dnf install -y "$pkg" || warn "Gagal install (dnf): $pkg"
done

log "Install driver NVIDIA (akmod-nvidia)"
sudo dnf install -y kernel-devel kernel-headers akmod-nvidia xorg-x11-drv-nvidia-cuda \
  || warn "Gagal install driver NVIDIA"
warn "akmod build driver di background, tunggu beberapa menit lalu REBOOT. Cek status: akmods-status"
warn "Kalau Secure Boot aktif di BIOS, module nvidia butuh di-enroll (MOK) saat reboot pertama."

log "Install Flatpak apps"
for app in "${FLATPAK_PACKAGES[@]}"; do
  sudo flatpak install -y flathub "$app" || warn "Gagal install (flatpak): $app"
done

log "Install Brave browser (official installer)"
curl -fsS https://dl.brave.com/install.sh | sh || warn "Gagal install Brave"

log "Install Zed IDE (official installer)"
curl -f https://zed.dev/install.sh | sh || warn "Gagal install Zed"

log "Install npm global CLI tools"
for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do
  sudo npm install -g "$pkg" || warn "Gagal install (npm): $pkg"
done
# ponytail: sudo npm -g nulis ke /usr milik root. Kalau mau tanpa sudo,
# set prefix npm ke folder user sendiri (npm config set prefix ~/.npm-global).

log "Install Oh My Zsh + plugin (autosuggestions, syntax highlighting)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || warn "Gagal install Oh My Zsh"
else
  warn "Oh My Zsh udah ada, skip install."
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
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
  sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
fi

log "Set zsh sebagai default shell"
sudo usermod -s "$(command -v zsh)" "$USER" || warn "Gagal ganti default shell ke zsh"
warn "Default shell baru kepake setelah logout/login ulang."

log "Install Orchis GTK theme"
tmp=$(mktemp -d)
mkdir -p "$HOME/.themes" "$HOME/.icons"
if git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git "$tmp/orchis"; then
  "$tmp/orchis/install.sh" -d "$HOME/.themes" || warn "Gagal install Orchis theme"
else
  warn "Gagal clone Orchis-theme"
fi

log "Install Colloid icon theme"
if git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git "$tmp/colloid"; then
  "$tmp/colloid/install.sh" -d "$HOME/.icons" || warn "Gagal install Colloid icon theme"
else
  warn "Gagal clone Colloid-icon-theme"
fi
rm -rf "$tmp"

log "Selesai. Reboot disarankan (driver NVIDIA baru selesai load setelah restart)."
