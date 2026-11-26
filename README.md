# Fedora Workstation Setup

Modular, idempotent setup suite untuk mengembalikan seluruh environment **Fedora Workstation** (GNOME Wayland) dari fresh install — meliputi paket dasar, Docker, NVIDIA, Zsh/NVM, audio hi-res PipeWire, tema & GNOME extensions, true-zero brightness, GRUB theme `mono-minimal`, pemeliharaan laptop otomatis, keyboard backlight Clevo, hotspot 5 GHz Intel Wi-Fi, hingga AI stack (**OmniRoute + Hermes Agent + Claude Code**).

## Quick Start

```bash
git clone https://github.com/faridfirdaus-fred/setup-fedora.git ~/setup-fedora
cd ~/setup-fedora
./install.sh
```

Jalankan modul tertentu saja atau lewati modul hardware tertentu:

```bash
./install.sh --list                               # Lihat semua modul
./install.sh --skip nvidia,clevo,hotspot          # Mesin Fedora generik / VM
./install.sh --only desktop,grub,maintenance      # Desktop + GRUB + maintenance saja
OMNIROUTE_API_KEY=sk-... ./install.sh --only ai   # Setup OmniRoute + Hermes + Claude Code
```

## Modul yang Tersedia

| Modul | Script | Cakupan |
|-------|--------|---------|
| `base` | `scripts/01-base-packages.sh` | DNF upgrade, RPM Fusion (free + nonfree), Flathub, paket DNF inti, Docker CE, Flatpak apps, Brave, Zed, VS Code, pip user packages, `thermald`/`smartd`/`fstrim.timer` |
| `nvidia` | `scripts/02-nvidia.sh` | Driver NVIDIA proprietary (`akmod-nvidia` + CUDA); otomatis skip jika GPU NVIDIA tidak terdeteksi |
| `shell` | `scripts/03-shell-dev.sh` | Zsh (default shell), Oh My Zsh + `zsh-autosuggestions` & `zsh-syntax-highlighting`, NVM + Node LTS, npm global CLIs (`claude`, `codex`, `cline`, `omniroute`, `opencode-ai`, `9router`, `kilocode`, `codebuddy`, `ast-grep`, `nestjs`, `pnpm`, `repomix`), PATH `~/.local/bin` |
| `audio` | `scripts/04-audio.sh` | PipeWire hi-res audio (`96 kHz` default, allowed `44.1–192 kHz`) di `~/.config/pipewire/pipewire.conf.d/10-hires.conf` |
| `desktop` | `scripts/05-desktop-gnome.sh` | Orchis GTK theme, Colloid icons, Geist / Geist Mono fonts, GNOME dark mode & tweaks, `brightness-zero` (layar sampai 0%), custom keybindings, GNOME Shell extensions + dconf presets |
| `grub` | `scripts/06-grub-theme.sh` | GRUB2 theme `mono-minimal` (black & white minimalist, font Geist, 1080p) lengkap dengan backup otomatis & `uninstall.sh` |
| `maintenance` | `scripts/07-laptop-maintenance.sh` | `laptop-maintenance` (user) + `laptop-maintenance-system` (root) + weekly systemd timers (Minggu 09:00 & 09:10) |
| `clevo` | `scripts/08-clevo-backlight.sh` | Clone & install [`clevo-backlight`](https://github.com/faridfirdaus-fred/clevo-backlight) (DKMS `tuxedo-keyboard`, `kbdlight`, `kbdlightd`); auto-detect hardware Clevo/Axioo |
| `hotspot` | `scripts/09-hotspot-intel.sh` | Clone & install [`hotspot-linux`](https://github.com/faridfirdaus-fred/hotspot-linux) (patched `iwlmvm` LAR-disabled + `create_ap` + CLI `hotspot-on/off/setting/status`); auto-detect Intel Wi-Fi & Secure Boot |
| `ai` | `scripts/10-ai-stack.sh` | OmniRoute loopback (`127.0.0.1:20128`) + `systemd --user` service + linger, Hermes Agent + konfigurasi routing via `hermes config set`, Claude Code `~/.claude/settings.json` template |

## Detail Konfigurasi Utama

### 1. Desktop GNOME, Tema, Extensions & Shortcut

- **Tema & Font**: `prefer-dark`, icon theme `Colloid`, GTK theme `Orchis` (`~/.themes`), UI font `Geist 11`, document `Geist 12`, monospace `Geist Mono 11`, text scaling `1.1`, battery percentage ON, button layout `appmenu:minimize,maximize,close`.
- **GNOME Extensions aktif** (`configs/gnome/extensions.txt` + `configs/gnome/extensions.dconf`):
  - `simple-taskbar@sultech` (mode taskbar horizontal)
  - `perfect-fit@ryliov.work.com`
  - `blur-my-shell@aunetx`
  - `just-perfection-desktop@just-perfection`
  - `tilingshell@ferrarodomenico.com`
  - `clipboard-indicator@tudmotu.com`
  - `appindicatorsupport@rgcjonas.gmail.com`
  - `windowgesturesrevived@vanceral.github.io`
  - `background-logo@fedorahosted.org`
- **True-Zero Brightness** (`bin/brightness-zero`): bypass batas minimum 1% Mutter via `brightnessctl` sambil menyinkronkan slider Quick Settings Mutter dan notifikasi HUD transient.
- **Custom Keybindings**:
  - `Super + T` → `ptyxis --new-window`
  - `XF86MonBrightnessDown` / `Up` → `~/.local/bin/brightness-zero down|up` (bisa turun sampai 0%)
  - `Super + F4` / `F2` / `F3` → `/usr/local/bin/kbdlight toggle|up|down`

### 2. GRUB2 Boot Theme (`grub/mono-minimal`)

Tema black & white minimalist dengan font `Geist` (`.pf2`), 9-slice UI widgets, dan icon OS monokrom (Fedora, Windows, UEFI, Recovery, Restart, Shutdown).

```bash
# Install / reinstall
sudo bash grub/mono-minimal/install.sh

# Rebuild asset (.pf2 & PNG) jika ingin ubah style (butuh python3-pillow & vercel-geist-fonts)
python3 grub/mono-minimal/build_theme.py

# Revert ke GRUB bawaan Fedora
sudo bash grub/mono-minimal/uninstall.sh
```

### 3. Laptop Maintenance Otomatis (`bin/laptop-maintenance*`)

Menjaga disk tetap bersih tanpa menyentuh file sensitif (misalnya `~/.cache/orca`, `mesa_shader_cache`, `fontconfig`):

- **User timer** (`laptop-maintenance.timer`, Minggu 09:00): Trash >14 hari, cache browser (Brave/Firefox/Chromium), Flatpak user cache >7 hari, thumbnails, libdnf5/flatpak user cache, npm/pnpm/pip/uv cache, Podman rootless dangling images.
- **System timer** (`laptop-maintenance-system.timer`, Minggu 09:10): `dnf5 clean all`, `journalctl --vacuum-time=14d --vacuum-size=200M`, `flatpak uninstall --unused`, `systemd-tmpfiles --clean`, coredump >7 hari, Docker dangling image/build cache >7 hari.

Pemakaian manual:
```bash
laptop-maintenance --status          # Cek ukuran cache, Trash, journal & jadwal timer
laptop-maintenance --dry-run         # Simulasi pembersihan user
laptop-maintenance --all             # Jalankan pembersihan user + sistem
laptop-maintenance --aggressive      # Bersihkan semua cache tanpa batas umur
```

### 4. Keyboard Backlight Clevo & Intel 5 GHz Hotspot

Keduanya dikelola di repo terpisah dan otomatis di-clone & dijalankan oleh modul `clevo` dan `hotspot`:

- **Clevo Keyboard Backlight**: https://github.com/faridfirdaus-fred/clevo-backlight
  - Perintah: `kbdlight on|off|up|down|toggle|color <hex>|status`
- **Intel Wi-Fi 5 GHz Hotspot**: https://github.com/faridfirdaus-fred/hotspot-linux
  - Perintah: `hotspot-setting`, `hotspot-on`, `hotspot-off`, `hotspot-status`
  - Catatan: butuh Secure Boot **disabled** di BIOS (modul `iwlmvm.ko` override unsigned). Untuk ganti kode negara: `HOTSPOT_COUNTRY=US ./install.sh --only hotspot`.

### 5. AI Stack: OmniRoute + Hermes Agent + Claude Code

Repo ini **tidak menyimpan API key, token OAuth, atau credential apa pun**. Semua rahasia tetap lokal di mesin Anda (`~/.omniroute/.env`, `~/.hermes/.env`, `~/.claude/settings.json`).

Arsitektur:
- **OmniRoute** berjalan sebagai `systemd --user` service (`omniroute.service`) dengan `loginctl enable-linger`, bind khusus loopback `OMNIROUTE_SERVER_HOST=127.0.0.1` pada port `20128` (tanpa MITM port 443).
- **Combos referensi** (`configs/ai/omniroute-combos.json`):
  - `daily` — primary coding & agent loop
  - `planner` — deep planning / architecture
  - `quick` — auxiliary/lightweight tasks (compression, titles, triage, monitoring)
- **Hermes Agent** dikonfigurasi lewat `configs/ai/hermes-setup.sh` menggunakan `hermes config set`:
  - Provider `providers.omniroute` → `http://localhost:20128/v1` (`key_env: OMNIROUTE_API_KEY`)
  - Default model `daily`, delegation `omniroute/daily`, `agent.reasoning_effort: xhigh`
  - Auxiliary tasks ringan diarahkan ke `quick`, vision/review/curator/moa ke `daily`
- **Claude Code** diarahkan ke `http://localhost:20128` lewat `configs/ai/claude-settings.json.template`:
  - Sonnet → `daily`, Opus/Fable → `planner`, Haiku → `quick`

Langkah aktivasi sekali jalan di mesin baru:
1. Jalankan `./install.sh --only ai`.
2. Buka `http://localhost:20128`, hubungkan akun provider upstream, buat combo `daily`, `planner`, `quick` sesuai `configs/ai/omniroute-combos.json`, lalu generate API key.
3. Masukkan API key ke `~/.hermes/.env` (`OMNIROUTE_API_KEY=<key>`) dan `~/.claude/settings.json` (`env.ANTHROPIC_AUTH_TOKEN`).
4. Verifikasi:
   ```bash
   ss -tlnp | grep 20128
   systemctl --user status omniroute.service
   hermes doctor
   claude -p 'Reply with just OK' --model sonnet --max-turns 1 --no-session-persistence
   ```

## Daftar Aplikasi yang Terpasang

- **DNF**: `alacritty`, `zsh`, `fzf`, `ripgrep`, `bat`, `eza`, `htop`, `tmux`, `jq`, `tree`, `git`, `gh`, `gcc-c++`, `make`, `python3` (+ `pip`, `devel`), `nodejs`, `gdb`, `dkms`, `kernel-devel`, `vercel-geist-fonts`, `vercel-geist-mono-fonts`, `gnome-tweaks`, `sassc`, `librsvg2`, `vlc`, `mpv`, `ffmpeg`, `bleachbit`, `baobab`, `brightnessctl`, `thunderbird`, `libreoffice-writer/calc/impress`, `sqlitebrowser`, `evince`, `pavucontrol`, `wireshark`, `nmap`, `tcpdump`, `aria2`, `flatpak`, `hostapd`, `dnsmasq`, `thermald`, `smartmontools`, `nvme-cli`, `compsize`, `btrfs-progs`, `docker-ce` (+ `buildx`, `compose`)
- **Flatpak (Flathub)**: Spotify, Obsidian, Discord, ProtonVPN, qbz, Extension Manager, EasyEffects, OBS Studio, Gear Lever
- **Official Installers / Repos**: Brave Browser, Visual Studio Code, Zed IDE, Hermes Agent
- **Global npm (via NVM LTS)**: `@anthropic-ai/claude-code`, `@openai/codex`, `cline`, `omniroute`, `opencode-ai`, `9router`, `@kilocode/cli`, `@tencent-ai/codebuddy-code`, `@ast-grep/cli`, `@nestjs/cli`, `corepack`, `pnpm`, `repomix`
- **Manual / AppImage**: Orca IDE (`~/AppImages/orca.appimage` via Gear Lever), Antigravity (`/opt/antigravity`)

## After Running

1. **Reboot** agar driver NVIDIA (`akmod-nvidia`), GRUB theme `mono-minimal`, default shell `zsh`, grup `docker`/`wireshark`, dan GNOME extensions aktif penuh.
2. Jika menggunakan **EasyEffects**, import preset AutoEQ untuk IEM/headphone Anda.
3. Selesaikan aktivasi API key OmniRoute di `~/.hermes/.env` dan `~/.claude/settings.json`.
