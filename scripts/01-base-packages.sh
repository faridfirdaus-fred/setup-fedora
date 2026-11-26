#!/usr/bin/env bash
# 01-base-packages.sh — RPM Fusion, Flathub, DNF packages, Docker CE, Flatpak apps,
# Brave, Zed, VS Code, pip user tools, and core system health services.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
require_non_root

DNF_PACKAGES=(
  # --- Terminal & shell ---
  alacritty
  zsh
  fzf
  ripgrep
  bat
  eza
  htop
  tmux
  jq
  tree
  curl
  wget2-wget

  # --- Development tools ---
  git
  gh
  gcc-c++
  make
  python3
  python3-pip
  python3-devel
  nodejs
  gdb
  dkms
  kernel-devel

  # --- Fonts & desktop theming ---
  vercel-geist-fonts
  vercel-geist-mono-fonts
  gnome-tweaks
  sassc
  librsvg2

  # --- Media & graphics ---
  vlc
  mpv
  ffmpeg
  bleachbit
  baobab
  brightnessctl

  # --- Productivity & office ---
  thunderbird
  libreoffice-writer
  libreoffice-calc
  libreoffice-impress
  sqlitebrowser
  evince

  # --- System, networking & hardware utilities ---
  pavucontrol
  wireshark
  nmap
  tcpdump
  aria2
  flatpak
  hostapd
  dnsmasq
  thermald
  smartmontools
  nvme-cli
  compsize
  btrfs-progs
)

FLATPAK_PACKAGES=(
  # --- Communication & media ---
  com.spotify.Client
  md.obsidian.Obsidian
  com.discordapp.Discord
  com.protonvpn.www
  com.blitzfc.qbz

  # --- Utilities & creation ---
  com.mattjakeman.ExtensionManager
  com.github.wwmm.easyeffects
  com.obsproject.Studio
  it.mijorus.gearlever

  # --- Optional (uncomment jika perlu) ---
  # org.zotero.Zotero
)

PIP_USER_PACKAGES=(
  yt-dlp
  matplotlib
  numpy
  requests
  python-pptx
  python-docx
  rich
  xlsxwriter
)

log "Update sistem Fedora"
sudo dnf upgrade --refresh -y

log "Enable RPM Fusion (free + nonfree)"
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
  || warn "Gagal enable RPM Fusion"

log "Enable Flathub"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Install paket DNF"
sudo dnf install -y --skip-unavailable "${DNF_PACKAGES[@]}" \
  || {
    warn "Batch DNF gagal sebagian, mencoba per paket..."
    for pkg in "${DNF_PACKAGES[@]}"; do
      sudo dnf install -y "$pkg" || warn "Gagal install (dnf): $pkg"
    done
  }

log "Izinkan capture paket non-root (wireshark)"
sudo usermod -aG wireshark "$USER" || warn "Gagal tambah user ke grup wireshark"

log "Aktifkan service kesehatan hardware (thermald, smartd, fstrim.timer)"
sudo systemctl enable --now thermald 2>/dev/null || true
sudo systemctl enable --now smartd 2>/dev/null || true
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

log "Install Docker CE (repo resmi)"
sudo dnf install -y dnf5-plugins 2>/dev/null || sudo dnf install -y dnf-plugins-core || true
sudo dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
  || sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
  || warn "Gagal add repo Docker"
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  || warn "Gagal install Docker"
sudo systemctl enable --now docker || warn "Gagal enable service Docker"
sudo usermod -aG docker "$USER" || warn "Gagal tambah user ke grup docker"

log "Install Flatpak apps"
for app in "${FLATPAK_PACKAGES[@]}"; do
  sudo flatpak install -y flathub "$app" || warn "Gagal install (flatpak): $app"
done

log "Install Brave browser (installer resmi)"
if ! command -v brave-browser >/dev/null 2>&1; then
  curl -fsS https://dl.brave.com/install.sh | sh || warn "Gagal install Brave"
else
  ok "Brave sudah terpasang."
fi

log "Install Zed IDE (installer resmi)"
if ! command -v zed >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/zed" ]]; then
  curl -f https://zed.dev/install.sh | sh || warn "Gagal install Zed"
else
  ok "Zed sudah terpasang."
fi

log "Install Visual Studio Code (repo Microsoft)"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf install -y code || warn "Gagal install Visual Studio Code"

log "Install pip packages (user)"
for pkg in "${PIP_USER_PACKAGES[@]}"; do
  python3 -m pip install --user --upgrade "$pkg" || warn "Gagal install (pip): $pkg"
done

ok "Base packages selesai."
