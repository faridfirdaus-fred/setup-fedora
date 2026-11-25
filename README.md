# Fedora Workstation Setup

Automated setup script for a fresh Fedora Workstation install. Dibuat untuk migrasi dari **Ubuntu → Fedora** dengan semua aplikasi yang sudah dipakai di laptop sekarang.

## Included

**DNF** — alacritty, zsh, fzf, ripgrep, bat, eza, htop, tmux, git, gh, gcc-c++, make, python3 (+ pip, venv, devel), nodejs, gdb, vlc, mpv, ffmpeg, bleachbit, baobab, brightnessctl, thunderbird, libreoffice-writer/calc/impress, zotero, sqlitebrowser, gnome-tweaks, pavucontrol, wireshark, nmap, tcpdump, aria2, evince, flatpak, **orca** (screen reader GNOME)

Enable **RPM Fusion** (free + nonfree) & **Flathub**

**NVIDIA driver** (akmod-nvidia) — untuk GPU NVIDIA

**Docker** (repo resmi): docker-ce, containerd.io, buildx, compose plugin — service enabled, user ditambah ke grup `docker`

**Flatpak** — Spotify, Obsidian, **Discord**, ProtonVPN, Extension Manager, EasyEffects, OBS Studio, + seluruh suite **ArtCraft** (artcraft-launcher, deckcraft, filmcraft, pdfcraft, photocraft, wordcraft), qbz, mailcraft, gearlever

**Browser/IDE via official installer** — **Brave**, Zed, **Visual Studio Code** (repo Microsoft)

**Google Cloud CLI** (gcloud) — via DNF (fallback snap)

**NVM** (Node Version Manager) + Node LTS

**npm global** — **claude** (`@anthropic-ai/claude-code`), codex, **cline**, **omniroute**, opencode, 9router, @ast-grep/cli, @kilocode/cli, @nestjs/cli, @tencent-ai/codebuddy-code, corepack, pnpm, repomix

**pip (user)** — yt-dlp, matplotlib, numpy, requests, python-pptx, python-docx, rich

**Zsh** + Oh My Zsh + zsh-autosuggestions & zsh-syntax-highlighting, default shell

Hi-res audio PipeWire (96 kHz default)

Tema: Orchis (GTK) + Colloid (icon)

## Usage

```bash
git clone git@github.com:faridfirdaus-fred/setup-fedora.git setup-fedora
cd setup-fedora
./install.sh
```

Butuh sudo (dipanggil otomatis di dalam script, akan meminta password beberapa kali).

## Daftar aplikasi yang di-migrasi dari Ubuntu

| Aplikasi | Di Ubuntu | Cara install di Fedora |
|----------|-----------|------------------------|
| Discord | apt `discord` | Flatpak `com.discordapp.Discord` |
| Spotify | apt `spotify-client` | Flatpak `com.spotify.Client` |
| Python | apt `python3*` | DNF `python3`, `python3-pip`, `python3-venv`, `python3-devel` |
| Node.js | apt `nodejs` | DNF `nodejs` + **NVM** untuk manage versi |
| NVM | `~/.nvm` | Install script ke `~/.nvm`, dimuat otomatis di `.zshrc` |
| Brave | apt `brave-browser` | Installer resmi `dl.brave.com/install.sh` |
| Orca | apt `orca` | DNF `orca` — screen reader GNOME |
| OmniRoute | npm global | `npm install -g omniroute` via NVM |
| Claude | npm global | `npm install -g @anthropic-ai/claude-code` via NVM |
| Cline | npm global | `npm install -g cline` via NVM |
| VS Code | apt `code` | Repo Microsoft → DNF `code` |
| Kiro | `/usr/share/kiro` | Custom install (unduh ulang dari kiro.dev) |
| Zotero | apt `zotero` | DNF `zotero` |
| VLC | apt `vlc` | DNF `vlc` |
| ArtCraft suite | Flatpak `ai.storyteller.*` | Flatpak (semua 6 app) |
| Obsidian | Flatpak | Flatpak `md.obsidian.Obsidian` |
| OBS Studio | Flatpak `com.obsproject.Studio` | Flatpak |
| gcloud | snap `google-cloud-cli` | DNF `google-cloud-cli` |
| yt-dlp | pip | `pip3 install --user yt-dlp` |
| Antigravity / Antigravity-IDE | `/opt/*` | Custom install (pindahkan /opt atau unduh ulang) |
| Free Download Manager | `/opt/freedownloadmanager` | Custom install (unduh ulang) |
| TwinDesk | AppImage di `~/AppImages` | Pindahkan file `.appimage` ke Fedora |

## Editing the app list

Buka `install.sh` dan edit array `DNF_PACKAGES`, `FLATPAK_PACKAGES`, `NPM_GLOBAL_PACKAGES`, atau `PIP_USER_PACKAGES` di bagian atas. Cari Flatpak app ID di https://flathub.org.

## After running

- **Reboot** — driver NVIDIA hanya aktif setelah restart.
- Jika Secure Boot aktif di BIOS, reboot pertama akan menampilkan layar biru MOK (Machine Owner Key) untuk tanda tangan driver NVIDIA — ikuti petunjuk layar (pilih Enroll MOK, masukkan password yang di-set saat install akmod).
- Apply tema Orchis + ikon Colloid via **GNOME Tweaks** → Appearance tab.
- Log out/in lagi (atau reboot) agar zsh sebagai default shell dan grup `wireshark`/`docker` berlaku.
- Buka **EasyEffects**, cari model IEM di [AutoEQ](https://github.com/jaakkopasanen/AutoEQ), dan import preset EQ yang cocok.
- Kalau DAC/IEM tidak bisa 96 kHz, sesuaikan `default.clock.rate` di `~/.config/pipewire/pipewire.conf.d/10-hires.conf` (misal 48000 atau 192000).
- Aplikasi custom (Antigravity, Kiro, FDM, TwinDesk) perlu dipindahkan/diunduh ulang secara manual — lihat catatan di akhir output script.
