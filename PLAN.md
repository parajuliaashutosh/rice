# `minimal` branch — plan

Goal: run `./install.sh` on a **bare Fedora (Everything netinstall "Minimal" or Fedora Server
minimal)** and end up with a light, good-looking Hyprland desktop, **same keybinds and monitor
setup as `main`**, but without end-4 / quickshell.

Nothing is built yet — this file is for review first. Items marked **[choose]** are open
questions; the recommended pick is listed first.

---

## 1. What changes vs `main`

| | `main` | `minimal` |
|---|---|---|
| shell / bar | end-4 illogical-impulse (quickshell, QML) | **Waybar** |
| launcher | quickshell overview (fuzzel fallback) | **fuzzel** |
| notifications | quickshell | **mako** |
| lock | quickshell lock (hyprlock fallback) | **hyprlock** (existing `hyprlock.conf`) |
| idle | hypridle | hypridle (same timings: 5m lock, 10m screen off, 15m suspend) |
| wallpaper | quickshell + matugen | **swaybg** (or hyprpaper) + existing `wallpaper-rotate.sh` |
| login | GDM/SDDM from end-4 | **tty1 → `start-hyprland`** (or greetd) |
| `base`, `quickshell` modules | yes | **removed on this branch** |
| keybinds, monitor, gestures, rules | Lua config | **kept**; only the quickshell calls are swapped |

Rough idle RAM (from experience, not measured on this machine yet; I'll measure after install):
quickshell/ii is usually **~300–600 MB** on its own. Waybar + mako + swaybg + hypridle is
**~60–120 MB** together, and fuzzel only uses memory while it's open.

---

## 2. Packages (official Fedora repo first, COPR `sdegler/hyprland` only where needed)

Checked with `dnf repoquery` on Fedora 44:

- **COPR sdegler/hyprland** (needed: Fedora's own Hyprland is too old for the Lua config):
  `hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprpicker waybar`
  (waybar is in the COPR build; Fedora's own `waybar` gets used if the COPR one is missing)
- **Fedora repos**: `fuzzel mako swaybg grim slurp wl-clipboard cliphist brightnessctl playerctl
  libnotify pipewire wireplumber pipewire-pulseaudio pavucontrol xdg-desktop-portal-gtk
  qt6-qtwayland xorg-x11-server-Xwayland mesa-dri-drivers mesa-vulkan-drivers xdg-user-dirs
  xdg-utils gnome-keyring jq curl`
- **Fonts/icons**: `jetbrains-mono-fonts-all google-noto-sans-fonts google-noto-color-emoji-fonts
  fontawesome-6-free-fonts adwaita-icon-theme` + a Nerd Font (JetBrainsMono NF, downloaded from
  the official nerd-fonts GitHub release into `~/.local/share/fonts`, since Fedora doesn't package it)
- **Optional extras**: `blueman`/`bluez` (Bluetooth), `network-manager-applet` (tray wifi),
  `thunar` (file manager), `wlogout` (power menu)

A minimal install has no audio, fonts, portals or graphical target. The new `session`
module installs those so the script works from scratch.

---

## 3. Keybinds: what each quickshell bind becomes

Everything that isn't quickshell (workspaces, window moves, media, volume, screenshots with
grim, zoom, `SUPER+P` display picker, apps) stays **exactly as it is**.

| key | main (quickshell) | minimal |
|---|---|---|
| `SUPER` (tap) | search overlay | `fuzzel` app launcher |
| `SUPER+V` | clipboard panel | `cliphist list \| fuzzel --dmenu \| cliphist decode \| wl-copy` |
| `SUPER+.` | emoji panel | existing `fuzzel-emoji.sh` |
| `SUPER+Tab` | workspace overview | fuzzel window switcher (small script on `hyprctl clients`) **[choose]** |
| `SUPER+A` / `SUPER+N` | sidebars | `SUPER+N` = mako history/dismiss; `SUPER+A` unbound **[choose]** |
| `CTRL+ALT+Del` | session menu | fuzzel power menu (lock/logout/suspend/reboot/poweroff) |
| `SUPER+SHIFT+S` | region snip | `grim -g "$(slurp)" - \| wl-copy` |
| `SUPER+SHIFT+R` | recorder | `wf-recorder` script (toggle) |
| `SUPER+L` | lock | `loginctl lock-session` → hyprlock (same) |
| `CTRL+SUPER+T` | wallpaper picker | fuzzel list of `~/Pictures/Wallpapers` → swaybg |
| `XF86MonBrightness*` | qs brightness OSD | `brightnessctl` (+ a `notify-send` progress bar via mako) |
| `SUPER+Escape` | qs-rescue | `pkill waybar; waybar &` (restart bar) |

`SUPER+P` (display picker), `display_mode.sh`, the stale-HDMI fix, scale 1: **unchanged**.

---

## 4. Bar layout (Waybar), ported from your current bar

Left: Fedora logo · workspaces
Center: clock · AD date · **Nepali (BS) date** (the AD→BS logic from `NepaliDate.qml` ported to a
small script) · click opens hamropatro.com
Right: weather Kathmandu (wttr.in, cached 30 min) · ↓/↑ net speed · CPU/RAM/swap · battery ·
backlight · volume · tray

Style: one floating, rounded, slightly transparent bar with no blur (blur costs GPU, not RAM, so
it can stay on in Hyprland if you like it).

---

## 5. Look / theme  **[choose]**

1. **Tokyo Night** (recommended: kitty already uses it, so everything matches)
2. Catppuccin Mocha (official ports exist for waybar/fuzzel/mako/hyprlock)
3. Gruvbox dark
4. Colors from the wallpaper (matugen/pywal). Nicest, but it adds a dependency and rewrites
   colors on every wallpaper change

Palette lives in one file; waybar CSS, fuzzel.ini, mako config and hyprlock colors.conf all
read from it. That replaces the matugen-generated `colors.lua`/`colors.conf` that `main` needs.

Borrowing other dotfiles: I looked at several "minimal Hyprland + Waybar" repos. Most are
Arch-only, tied to pywal/swaync, or stale, so I wouldn't import a whole repo. I'd write our
own small config and copy palettes and CSS from the **official theme ports**
(catppuccin/waybar, tokyonight extras), which are MIT licensed and maintained. If you have a
specific repo/screenshot you like, I can base the bar on that instead.

---

## 6. Login  **[choose]**

1. **tty1 autostart** (recommended, lightest): log in on the text console, and
   `~/.zprofile` runs `exec start-hyprland` on tty1. Costs 0 MB.
2. **greetd + tuigreet**: small text login screen (both in Fedora repos), a few MB.
3. SDDM/GDM: graphical, but pulls in a lot. Not recommended for this goal.

---

## 7. Swap / memory script (new `swap` module, `./install.sh swap`)

Fedora already ships **zram** (`zram-generator-defaults`: compressed swap in RAM, size =
min(RAM, 8 GB)). The script will:

1. Write `/etc/systemd/zram-generator.conf`: `zram-size = ram` (or your choice),
   `compression-algorithm = zstd`, `swap-priority = 100`.
2. Set sysctl for zram (`/etc/sysctl.d/99-rice-swap.conf`): `vm.swappiness = 180`,
   `vm.page-cluster = 0`, `vm.watermark_scale_factor = 125`. These are the values Fedora/ChromeOS
   use with zram.
3. Optionally add a **disk swapfile** as overflow (lower priority than zram), sized by you
   (default 8 GB). It handles both filesystems Fedora installs with:
   - btrfs (Workstation default): `btrfs subvolume create /swap` + `btrfs filesystem mkswapfile`
   - xfs/ext4 on LVM (**Server default**): `fallocate` + `mkswap`
   It adds the fstab entry and is idempotent (re-run = no change, or resize if you ask).
4. Optional `systemd-oomd` check, so a runaway app gets killed before the desktop freezes.
5. `./install.sh swap --status`-style output: zram size, swapfile, current usage.

**[choose]**: zram size (`ram` / `ram / 2` / keep 8 GB) and swapfile size (0 = none / 8 GB /
= RAM, which is what hibernate needs).

---

## 8. Repo changes on this branch

- delete `modules/base`, `modules/quickshell`, `qs-rescue.sh`, `shellOverrides/`
- `modules/hyprland`: strip quickshell from `execs.lua`, `keybinds.lua`, `general.lua`
  (gestures), `env.lua` (KDE/ii vars), `rules.lua`, `hypridle.conf`; static colors
- new modules: `session` (audio, portals, polkit, fonts, login), `waybar`, `fuzzel`, `mako`, `swap`
- `kitty`: drop the quickshell-generated theme include, use the static palette
- `lib/check.sh`: check waybar/mako running instead of quickshell; `lib/common.sh`: drop
  `RICE_END4_REF`
- README section for the minimal branch
- verify with `Hyprland --verify-config` here before committing; you test on the real install

## 9. Install on the new machine

```sh
sudo dnf install -y git
git clone -b minimal https://github.com/parajuliaashutosh/rice ~/rice
cd ~/rice && ./install.sh          # then reboot, log in on tty1
```
