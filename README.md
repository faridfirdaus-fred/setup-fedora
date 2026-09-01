# Fedora 44 Workstation Setup

Automated setup script for a fresh Fedora 44 Workstation install.

## Included

- Enable RPM Fusion (free + nonfree) & Flathub
- **DNF**: nodejs, gcc-c++, make, git, thunderbird, bleachbit, mpv, gnome-tweaks, pavucontrol, gh, wireshark, nmap, tcpdump, ripgrep, fzf, bat
- **NVIDIA driver** (akmod-nvidia) — for RTX 2050 GPU
- **Docker** (official repo): docker-ce, docker-ce-cli, containerd.io, buildx, compose plugin — service enabled, user added to `docker` group
- **Flatpak**: Spotify, Obsidian, Discord, ProtonVPN, Extension Manager, EasyEffects
- **Hi-res audio**: PipeWire config (`~/.config/pipewire/pipewire.conf.d/10-hires.conf`) raises default sample rate to 96kHz for IEM/DAC
- **Browser/IDE via official installer**: Brave, Zed
- **npm global**: claude-code, codex, cline, 9router
- **Zsh** + Oh My Zsh + zsh-autosuggestions (history-based autocomplete) & zsh-syntax-highlighting (colored highlighting), set as default shell
- **Theme**: Orchis (GTK) + Colloid (icon)

## Usage

```bash
git clone <repo-url> setup_fedora
cd setup_fedora
./install.sh
```

Requires sudo (called automatically inside the script, will prompt for password a few times).

## Editing the app list

Open `install.sh` and edit the `DNF_PACKAGES`, `FLATPAK_PACKAGES`, or `NPM_GLOBAL_PACKAGES` arrays near the top. Look up flatpak app IDs at https://flathub.org.

## After running

- **Reboot** — the NVIDIA driver only activates after a restart.
- If Secure Boot is enabled in BIOS, the first reboot will show a blue MOK (Machine Owner Key) enrollment screen for the NVIDIA driver signature — follow the on-screen prompts (choose Enroll MOK, enter the password set during akmod install).
- Apply the Orchis theme + Colloid icons via **GNOME Tweaks** → Appearance tab.
- **Log out/in again** (or reboot) so the zsh default shell takes effect.
- Open **EasyEffects**, search your IEM model on [AutoEQ](https://github.com/jaakkopasanen/AutoEQ), and import the matching preset for tuned EQ.
- If your DAC/IEM doesn't max out at 96kHz, adjust `default.clock.rate` in `~/.config/pipewire/pipewire.conf.d/10-hires.conf` to match its spec (e.g. 48000 or 192000).
- **Log out/in again** is also required for the `wireshark` (non-root packet capture) and `docker` (running `docker` without sudo) group membership to take effect.
