# `minimal` branch — plan

Goal: run `./install.sh` on a **bare Fedora (Everything netinstall "Minimal" or Fedora Server
minimal)** and end up with a light, good-looking Hyprland desktop, **same keybinds and monitor
setup as `main`**, but without end-4 / quickshell.

**Status: built** (see "Build notes" at the end for what was verified and how).

### Decisions (answered 2026-11-02)

- **Theme**: colors from the wallpaper (matugen, which is in Fedora's repo)
- **Login**: tty1 autostart → `start-hyprland`
- **Swap**: same as the current laptop (zram min(RAM, 8 GB) + 20 GB swapfile `/swap/swapfile`
  pri 10 + swappiness 60)
- **Extras**: all of them: Nepali date + weather, Bluetooth + wifi tray, SUPER+Tab window
  switcher, wallpaper rotation **with the same wallhaven list** (`wallpapers.txt`)

Still open: SUPER+A (sidebar on `main`) has no equivalent yet, so it stays unbound unless
you want something there.

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
- **Theming**: `matugen` (Fedora repo)
- **Included extras**: `bluez blueman` (Bluetooth, tray), `network-manager-applet` (wifi tray),
  `wf-recorder` (screen recording)
- Not included unless you ask: `thunar` (file manager), `wlogout`

Wallpapers: the same `wallpapers.txt` wallhaven list from `main`. `wallpaper-rotate.sh` still
downloads them to `~/Pictures/Wallpapers/rotation` and switches to the next one on each lock,
now using `swaybg` + matugen instead of quickshell's `switchwall.sh`.

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
| `SUPER+Tab` | workspace overview | fuzzel window switcher (small script on `hyprctl clients`) |
| `SUPER+A` / `SUPER+N` | sidebars | `SUPER+N` = mako history/dismiss; `SUPER+A` unbound (open) |
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

## 5. Look / theme: **colors from the wallpaper (decided)**

`matugen` (Fedora repo) runs on every wallpaper change, from `wallpaper-rotate.sh` and the
`CTRL+SUPER+T` picker, and fills small templates:

- `~/.config/waybar/colors.css` → waybar reloads (`pkill -SIGUSR2 waybar`)
- `~/.config/fuzzel/colors.ini` (included by `fuzzel.ini`)
- `~/.config/mako/config` (rebuilt from a template, then `makoctl reload`)
- `~/.config/hypr/hyprland/colors.lua` (border colors, same file `main` already loads)
- `~/.config/hypr/hyprlock/colors.conf` (same file `hyprlock.conf` already sources)

A **fallback palette** is committed for each one, so the first boot (before any wallpaper is
downloaded) still looks right and nothing breaks if matugen fails. kitty keeps its own fixed
Tokyo Night colors, same as on `main` (`enableTerminal = false`).

Borrowing other dotfiles: I looked at several "minimal Hyprland + Waybar" repos. Most are
Arch-only, tied to pywal/swaync, or stale, so I wouldn't import a whole repo. I'd write our
own small config and copy palettes and CSS from the **official theme ports**
(catppuccin/waybar, tokyonight extras), which are MIT licensed and maintained. If you have a
specific repo/screenshot you like, I can base the bar on that instead.

---

## 6. Login: **tty1 autostart (decided)**

Log in on the text console; `~/.zprofile` (zsh module) runs `exec start-hyprland` only on
tty1 and only when no Wayland session is running. Other ttys (Ctrl+Alt+F2…) stay plain shells
for rescue. The `session` module sets `systemctl set-default multi-user.target` only if a
display manager isn't already installed.

---

## 7. Swap / memory script (new `swap` module, `./install.sh swap`)

Copies what this laptop has today (checked 2026-11-02):

| | current laptop | swap module |
|---|---|---|
| zram | Fedora default `zram-size = min(ram, 8192)`, prio 100 | make sure `zram-generator-defaults` is installed (minimal installs may lack it) |
| swapfile | 20 GB `/swap/swapfile` on btrfs, `pri=10` in fstab | same path, size, priority |
| swappiness | 60 (`/etc/sysctl.d/99-zz-laptop-swappiness.conf`) | same file, same value |

The swapfile step handles both filesystems Fedora can install with:
- **btrfs** (Workstation/Everything default, like this laptop): `btrfs subvolume create /swap`
  + `btrfs filesystem mkswapfile --size 20g` (that command sets nodatacow for you)
- **xfs/ext4 on LVM** (Fedora **Server** default): `fallocate -l 20G` + `chmod 600` + `mkswap`

It skips the swapfile if the disk has less than 20 GB + 10 GB free and says so instead of
filling the disk. Override with `RICE_SWAPFILE_GB=8 ./install.sh swap` (0 = no file).
Idempotent: an existing `/swap/swapfile` of the right size is left alone.

---

## 8. Repo changes on this branch

- delete `modules/base`, `modules/quickshell`, `qs-rescue.sh`, `shellOverrides/`
- `modules/hyprland`: strip quickshell from `execs.lua`, `keybinds.lua`, `general.lua`
  (gestures), `env.lua` (KDE/ii vars), `rules.lua`, `hypridle.conf`; static colors
- new modules: `session` (audio, portals, polkit, fonts, login), `waybar`, `fuzzel`, `mako`, `swap`
- `kitty`: drop the quickshell-generated theme include; keeps its fixed Tokyo Night colors
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

---

## 10. Build notes (2026-11-02)

Module run order: `hyprland` first (it enables the COPR), then the rest by name, so `wallpaper`
runs before `waybar`. Fallback color files are copied in first, then matugen overwrites them
from the first wallpaper during install.

Things found while building that changed the plan:

- **Waybar must come from the COPR.** In Lua mode Hyprland rejects old-style
  `dispatch workspace 3`, and that's what Waybar 0.15.0 (Fedora's package) sends, so clicking a
  workspace would do nothing. The `sdegler/hyprland` COPR build (`0.15.0^2.git1684389`) includes
  upstream PRs #5013/#5231 (Lua dispatch). The waybar module swaps out Fedora's build if it's
  already installed.
- **matugen**: Fedora ships 3.1; the laptop has 4.1. v4 asks which color to use unless
  `--source-color-index` is given, and v3 doesn't know that flag. `wallpaper-set.sh` checks for it.
  The config needs a `[config]` table, or matugen refuses it.
- **Nerd Font**: on the laptop it comes from end-4's COPR. Here the `session` module downloads
  the official nerd-fonts release into `~/.local/share/fonts`.
- **Wifi/Bluetooth**: nm-applet and blueman-applet live in the tray, so there are no separate
  wifi/bluetooth modules in the bar (they would show the same icons twice).
- **Fuzzel**: `Super_L` is not a cancel key. The SUPER bind already toggles it, and cancel on
  press + launch on release would reopen it immediately.
- **Autostart off switch** is a file (`~/.config/rice/no-autostart`), not a variable: `.zprofile`
  runs before `.zshrc`, so a variable set in `~/.zshrc.local` would come too late.
- SUPER+A (left sidebar on `main`) is still unbound.

Verified on the laptop (read-only, nothing installed or changed there):
- `Hyprland --verify-config` on the full config tree in a temporary HOME, with both the fallback
  and a matugen-generated `colors.lua` (and a planted error to confirm the check catches errors)
- `fuzzel --check-config` with fallback and generated colors
- matugen rendering all five templates from a real wallpaper into a temp dir
- `bash -n` on every script; Nepali date checked against known New Year dates (2081-01-01 =
  13 Apr 2024, 2082-01-01 = 14 Apr 2025)

Verified in a throwaway VM (Fedora 44 Cloud Base, KVM, user-mode network): see section 11.
