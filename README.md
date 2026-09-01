# Fedora 44 Workstation Setup

Script instalasi otomatis pas fresh install Fedora 44 Workstation.

## Isi

- Enable RPM Fusion (free + nonfree) & Flathub
- **DNF**: nodejs, gcc-c++, make, git, thunderbird, bleachbit, mpv
- **Driver NVIDIA** (akmod-nvidia) — buat GPU RTX 2050
- **Flatpak**: Spotify, Obsidian, Discord, ProtonVPN
- **Browser/IDE via installer resmi**: Brave, Zed
- **npm global**: claude-code, codex, cline, 9router
- **Zsh** + Oh My Zsh + plugin zsh-autosuggestions (autocomplete history) & zsh-syntax-highlighting (warna), set jadi default shell
- **Theme**: Orchis (GTK) + Colloid (icon)

## Pakai

```bash
git clone <repo-url> setup_fedora
cd setup_fedora
./install.sh
```

Butuh sudo (dipanggil otomatis di dalam script, bakal nanya password sekali-dua kali).

## Edit daftar apps

Buka `install.sh`, edit array `DNF_PACKAGES`, `FLATPAK_PACKAGES`, atau `NPM_GLOBAL_PACKAGES` di bagian atas file. Cari flatpak app ID di https://flathub.org.

## Setelah run

- **Reboot** — driver NVIDIA baru aktif setelah restart.
- Kalau Secure Boot nyala di BIOS, pas reboot pertama bakal muncul layar biru MOK (Machine Owner Key) buat enroll signature driver NVIDIA — ikuti instruksi di layar (pilih Enroll MOK, masukin password yang diminta script akmod).
- Apply theme Orchis + icon Colloid lewat **GNOME Tweaks** (`dnf install gnome-tweaks` kalau belum ada) → tab Appearance.
- **Logout/login ulang** (atau reboot sekalian) biar shell default zsh kepake.

## Saran tambahan (belum masuk script, tinggal tambah ke array kalau mau)

- `podman` / `docker-ce` — kalau butuh container
- `gh` — GitHub CLI
- `ripgrep`, `fzf`, `bat` — dev quality-of-life di terminal
- `gnome-tweaks`, `gnome-extensions-app` — buat apply theme/icon di atas
- `distrobox` — jalanin distro lain dalam container, enak buat dev tools yang belum ada di Fedora
