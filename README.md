# Fedora Workstation Setup

Automated setup script for a fresh Fedora Workstation install. Dibuat untuk migrasi dari Ubuntu → Fedora dengan aplikasi yang sudah dipakai di laptop sekarang.

## Included

- **DNF**: nodejs, gcc-c++, make, git, python3 (+ pip, venv, devel), thunderbird, bleachbit, mpv, zsh, gnome-tweaks, pavucontrol, gh, wireshark, nmap, tcpdump, ripgrep, fzf, bat, **orca** (screen reader GNOME)
- Enable **RPM Fusion** (free + nonfree) & **Flathub**
- **NVIDIA driver** (akmod-nvidia) — untuk GPU NVIDIA
- **Docker** (repo resmi): docker-ce, containerd.io, buildx, compose plugin — service enabled, user ditambah ke grup `docker`
- **Flatpak**: Spotify, Obsidian, **Discord**, ProtonVPN, Extension Manager, EasyEffects
- **Browser/IDE via official installer**: **Brave**, Zed
- **NVM** (Node Version Manager) + Node LTS
- **npm global**: **claude** (`@anthropic-ai/claude-code`), codex, **cline**, **omniroute**, 9router
- **Zsh** + Oh My Zsh + zsh-autosuggestions & zsh-syntax-highlighting, default shell
- Hi-res audio PipeWire (96 kHz default)
- Tema: Orchis (GTK) + Colloid (icon)

## Usage

```bash
git clone git@github.com:faridfirdaus-fred/setup-fedora.git setup-fedora
cd setup-fedora
./install.sh
```

Butuh sudo (dipanggil otomatis di dalam script, akan meminta password beberapa kali).

## Daftar aplikasi yang di-migrasi dari Ubuntu

| Aplikasi | Cara install di Fedora |
|----------|------------------------|
| Discord | Flatpak (`com.discordapp.Discord`) |
| Python | DNF (`python3`, `python3-pip`, `python3-venv`, `python3-devel`) |
| Node.js | DNF (`nodejs`) + **NVM** untuk manage versi |
| NVM | Install script ke `~/.nvm`, dimuat otomatis di `.zshrc` |
| Brave | Installer resmi (`dl.brave.com/install.sh`) |
| Orca | DNF (`orca`) — screen reader GNOME |
| OmniRoute | npm global (`npm install -g omniroute` via NVM) |
| Claude | npm global (`@anthropic-ai/claude-code` via NVM) |
| Cline | npm global (`cline` via NVM) |

## Editing the app list

Buka `install.sh` dan edit array `DNF_PACKAGES`, `FLATPAK_PACKAGES`, atau `NPM_GLOBAL_PACKAGES` di bagian atas. Cari Flatpak app ID di https://flathub.org.

## After running

- **Reboot** — driver NVIDIA hanya aktif setelah restart.
- Jika Secure Boot aktif di BIOS, reboot pertama akan menampilkan layar biru MOK (Machine Owner Key) untuk tanda tangan driver NVIDIA — ikuti petunjuk layar (pilih Enroll MOK, masukkan password yang di-set saat install akmod).
- Apply tema Orchis + ikon Colloid via **GNOME Tweaks** → Appearance tab.
- Log out/in lagi (atau reboot) agar zsh sebagai default shell dan grup `wireshark`/`docker` berlaku.
- Buka **EasyEffects**, cari model IEM di [AutoEQ](https://github.com/jaakkopasanen/AutoEQ), dan import preset EQ yang cocok.
- Kalau DAC/IEM tidak bisa 96 kHz, sesuaikan `default.clock.rate` di `~/.config/pipewire/pipewire.conf.d/10-hires.conf` (misal 48000 atau 192000).
