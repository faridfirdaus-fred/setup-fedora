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
  # --- Terminal & shell ---
  alacritty
  zsh
  fzf
  ripgrep
  bat
  eza
  htop
  tmux

  # --- Development tools ---
  git
  gh
  gcc-c++
  make
  python3
  python3-pip
  python3-venv
  python3-devel
  nodejs
  gdb

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
  zotero
  sqlitebrowser

  # --- System utilities ---
  gnome-tweaks
  pavucontrol
  wireshark
  nmap
  tcpdump
  aria2
  evince
  flatpak

  # --- Accessibility ---
  orca
)

FLATPAK_PACKAGES=(
  # --- Communication ---
  com.spotify.Client            # Spotify
  md.obsidian.Obsidian
  com.discordapp.Discord        # Discord
  com.protonvpn.www

  # --- Utilities ---
  com.mattjakeman.ExtensionManager   # GNOME Extension Manager
  com.github.wwmm.easyeffects        # EQ + convolver (AutoEQ)
  com.obsproject.Studio              # OBS Studio

  # --- ArtCraft suite (ai.storyteller) ---
  ai.storyteller.artcraft-launcher
  ai.storyteller.deckcraft
  ai.storyteller.filmcraft
  ai.storyteller.pdfcraft
  ai.storyteller.photocraft
  ai.storyteller.wordcraft

  # --- Lainnya ---
  com.blitzfc.qbz
  io.github.billsecond.mailcraft
  it.mijorus.gearlever
)

NVM_VERSION="v0.40.3"

NPM_GLOBAL_PACKAGES=(
  # AI / coding assistants
  @anthropic-ai/claude-code  # claude
  @openai/codex              # codex
  cline                      # cline
  omniroute                  # omniroute
  opencode-ai                # opencode

  # JS/TS tooling
  9router
  @ast-grep/cli
  @kilocode/cli
  @nestjs/cli
  @tencent-ai/codebuddy-code
  corepack
  pnpm
  repomix
)

PIP_USER_PACKAGES=(
  yt-dlp
  matplotlib
  numpy
  requests
  python-pptx
  python-docx
  rich
)

# ============================================================

log "Update sistem"
sudo dnf upgrade --refresh -y

log "Enable RPM Fusion (free + nonfree)"
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
  || warn "Gagal enable RPM Fusion"

log "Enable Flathub"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Install paket DNF"
for pkg in "${DNF_PACKAGES[@]}"; do
  sudo dnf install -y "$pkg" || warn "Gagal install (dnf): $pkg"
done

log "Izinkan capture paket non-root (wireshark)"
sudo usermod -aG wireshark "$USER" || warn "Gagal tambah user ke grup wireshark"

log "Install Docker (repo resmi)"
sudo dnf install -y dnf-plugins-core || warn "Gagal install dnf-plugins-core"
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
  || warn "Gagal add repo Docker"
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  || warn "Gagal install Docker"
sudo systemctl enable --now docker || warn "Gagal enable service Docker"
sudo usermod -aG docker "$USER" || warn "Gagal tambah user ke grup docker"

log "Install driver NVIDIA (akmod-nvidia)"
sudo dnf install -y kernel-devel kernel-headers akmod-nvidia xorg-x11-drv-nvidia-cuda \
  || warn "Gagal install driver NVIDIA"
warn "akmod build driver di background, tunggu beberapa menit lalu REBOOT. Cek status: akmods-status"
warn "Kalau Secure Boot aktif di BIOS, module nvidia butuh di-enroll (MOK) saat reboot pertama."

log "Install Flatpak apps"
for app in "${FLATPAK_PACKAGES[@]}"; do
  sudo flatpak install -y flathub "$app" || warn "Gagal install (flatpak): $app"
done

log "Install Brave browser (installer resmi)"
curl -fsS https://dl.brave.com/install.sh | sh || warn "Gagal install Brave"

log "Install Zed IDE (installer resmi)"
curl -f https://zed.dev/install.sh | sh || warn "Gagal install Zed"

log "Install Visual Studio Code (repo Microsoft)"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' 2>/dev/null || true
sudo dnf install -y code || warn "Gagal install Visual Studio Code"

log "Install Google Cloud CLI (gcloud)"
sudo dnf install -y google-cloud-cli || warn "Gagal install google-cloud-cli (coba via snap: snap install google-cloud-cli --classic)"

log "Install NVM (Node Version Manager)"
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash || warn "Gagal install NVM"
else
  warn "NVM sudah ada, skip install."
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm >/dev/null 2>&1; then
  log "Install Node LTS via NVM + npm global CLI"
  nvm install --lts || warn "Gagal install Node LTS via nvm"
  nvm alias default 'lts/*' || warn "Gagal set default Node LTS"
  for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do
    npm install -g "$pkg" || warn "Gagal install (npm): $pkg"
  done
else
  warn "nvm tidak tersedia di sesi ini; lewati npm global."
fi

# Persist nvm di .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
  if ! grep -q 'export NVM_DIR' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" <<'ZSHRC_EOF'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
ZSHRC_EOF
  fi
fi

log "Install pip packages (user)"
for pkg in "${PIP_USER_PACKAGES[@]}"; do
  pip3 install --user "$pkg" || warn "Gagal install (pip): $pkg"
done

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

log "Config PipeWire buat hi-res audio (IEM/DAC)"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat > "$HOME/.config/pipewire/pipewire.conf.d/10-hires.conf" <<'EOF'
context.properties = {
  default.clock.rate          = 96000
  default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
}
EOF
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null \
  || warn "Restart PipeWire manual: systemctl --user restart pipewire pipewire-pulse wireplumber"
warn "Kalau DAC/IEM situ max 48k/96k, sesuaikan default.clock.rate di ~/.config/pipewire/pipewire.conf.d/10-hires.conf"

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

log "Catatan aplikasi custom (install manual setelah reboot):"
warn "- Antigravity CLI & Antigravity-IDE: ada di /opt di Ubuntu, instalasi custom (linuxcapable). Pindahkan folder /opt/antigravity dan /opt/antigravity-ide atau unduh ulang dari sumber resmi."
warn "- Kiro: ada di /usr/share/kiro (custom). Unduh ulang dari kiro.dev."
warn "- Free Download Manager: ada di /opt/freedownloadmanager. Unduh ulang dari freedownloadmanager.org."
warn "- TwinDesk AppImage: sudah ada di ~/AppImages/twindesk.appimage, pindahkan file AppImage ke Fedora."
warn "- Aplikasi snap (google-cloud-cli): kalau dnf gagal, coba 'snap install google-cloud-cli --classic'."

log "Selesai. Reboot disarankan (driver NVIDIA + grup wireshark/docker baru aktif setelah restart/relogin)."
