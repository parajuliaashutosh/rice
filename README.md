# rice — `minimal` branch

My dotfiles, light edition: **Hyprland + Waybar + fuzzel + mako**, made for a bare
**Fedora** install (Everything netinstall "Minimal" or Fedora Server). Same keybinds,
monitor setup, kitty, zsh and apps as `main`, but no end-4 / quickshell. See [PLAN.md](PLAN.md)
for why and what replaced what.

```sh
sudo dnf install -y git
git clone -b minimal https://github.com/parajuliaashutosh/rice.git ~/rice
cd ~/rice && ./install.sh
sudo reboot          # then log in on tty1: Hyprland starts by itself
```

What you get after login:

| keys | |
|---|---|
| tap `SUPER` | app launcher (fuzzel) |
| `SUPER+Tab` | switch window · `SUPER+/` keybind cheatsheet · `CTRL+ALT+Del` session menu |
| `SUPER+V` / `SUPER+.` | clipboard history / emoji |
| `CTRL+SUPER+T` | pick wallpaper (bar, launcher, notifications, borders and lock screen re-color from it) |
| `SUPER+L` | lock (hyprlock; next wallpaper from the wallhaven list on every lock) |
| `SUPER+Escape` | unstick: close launcher, restart bar + notifications |

Everything else (workspaces, windows, media, screenshots, `SUPER+P` display picker) is the
same as `main`.

## What it does

`install.sh` walks `modules/`, and for each module installs its dependencies
and symlinks its config into `$HOME`, file by file. If a file already sits where
a link needs to go it's moved aside to
`<file>.rice-bak` and replaced with the link — no questions. Re-running is safe:
anything already installed or linked is skipped, and no extra backups are made.

```sh
./install.sh              # all modules (asks about optional ones)
./install.sh zsh          # just one
./install.sh --list       # what's available
./install.sh --dry-run    # show the plan, change nothing
./install.sh --no-deps    # link configs only, skip package installs
./install.sh --check      # is everything installed, linked and loading? (also runs after every install)
```

Optional modules (pentest) and the app picker look first: they list what they'd install,
tick what's already there, and only ask about what's missing.

## Modules

| module | what it sets up |
|--------|-----------------|
| `hyprland` | Hyprland (from the `sdegler/hyprland` COPR on Fedora) + hyprlock/hypridle, the portal and polkit agent, all keybinds, SUPER+P display picker, helper scripts (window switcher, session menu, OSD, recorder). Always runs first |
| `session` | what a bare install lacks: PipeWire audio, portals, GPU drivers, Xwayland, wifi/bluetooth (+ tray applets), fonts incl. JetBrainsMono Nerd Font and Devanagari, dark GTK, and **tty1 login → Hyprland** (no display manager) |
| `waybar` | the bar: Fedora logo, workspaces, weather (Kathmandu, `RICE_WEATHER_CITY` to change), ↓/↑ net · clock, date, Nepali (BS) date · battery, CPU/RAM/swap, color picker, brightness, volume, tray |
| `fuzzel` | launcher and every menu; clipboard history via cliphist |
| `mako` | notifications + the volume/brightness OSD |
| `wallpaper` | swaybg + matugen: the wallhaven rotation list from `main`, colors from the wallpaper for bar/launcher/notifications/borders/lock |
| `swap` | same as the laptop: zram (Fedora default) + 20 GB `/swap/swapfile` (pri 10) + swappiness 60; btrfs or xfs/ext4. `RICE_SWAPFILE_GB=8` for another size, `0` for none |
| `apps` | asks which to install: Brave, Chrome, Firefox, VS Code, Docker (no sudo), kubectl, Slack, OBS, LibreOffice, Neovim (with my LazyVim config, plugins install on first launch). Official packages first. `RICE_APPS="all"` or `RICE_APPS="brave docker"` skips the question |
| `dev` | asks which to install: Node LTS (nvm), Java (SDKMAN), Python tooling (uv), Go. Only missing ones are offered; `RICE_DEV="all"` skips the question |
| `zsh`  | oh-my-zsh, powerlevel10k, autosuggestions, syntax highlighting, my shell config |
| `zed`  | the Zed editor and its settings (extensions install themselves on first launch) |
| `kitty` | kitty config; SUPER+Enter opens a tab in the workspace's kitty (SUPER+Shift+Enter for a new window) |
| `pentest` *(optional)* | Kali-style lab tooling on Fedora (see [Pentest](#pentest)); `~/labs/{thm,htb,vpn}` |

Optional modules (a `.optional` file in the module dir) are skipped by a bare
`./install.sh` unless you answer yes to its prompt. Naming one
(`./install.sh pentest`) installs it directly.

Future: `git` — see [MODULES.md](MODULES.md).

## Layout

```
rice/
├── install.sh              entry point
├── lib/common.sh           logging, symlinking, package install, COPR, git clone
└── modules/
    ├── apps/module.sh       app picker
    ├── session/             audio, portals, fonts, tty1 → Hyprland
    ├── waybar/ fuzzel/ mako/   bar, launcher, notifications (+ fallback colors)
    ├── wallpaper/           swaybg + matugen templates, wallhaven list
    ├── swap/module.sh       zram + swapfile
    ├── zsh/
    │   ├── module.sh       install steps for this module
    │   ├── zshrc.local.example
    │   └── home/           mirrored into $HOME
    │       ├── .zshrc
    │       ├── .p10k.zsh
    │       └── .config/zsh/conf.d/*.zsh
    ├── zed/
    │   ├── module.sh
    │   └── home/.config/zed/settings.json
    ├── hyprland/
    │   ├── module.sh
    │   ├── fallback/            colors until matugen runs
    │   └── home/.config/hypr/   (keybinds in hyprland/keybinds.lua)
    ├── kitty/
    │   ├── module.sh
    │   └── home/.config/kitty/  (kitty.conf + search/scroll kittens)
    └── pentest/                 opt-in (.optional), no config to link
        └── module.sh
```

## How the zsh config is organised

`~/.zshrc` is a thin loader. Everything real lives in numbered fragments under
`~/.config/zsh/conf.d/`, sourced in order:

| file | contents |
|------|----------|
| `05-env.zsh`       | `EDITOR`, `LANG`, XDG dirs, `RICE_DIR` |
| `10-omz.zsh`       | oh-my-zsh theme + plugin list |
| `20-options.zsh`   | history, `setopt`, completion, keybindings |
| `30-colors.zsh`    | autosuggestion + syntax-highlight palette |
| `40-path.zsh`      | `PATH`, built with existence-guarded helpers |
| `50-tools.zsh`     | android, bun, railway, mise, sdkman |
| `60-aliases.zsh`   | aliases |
| `70-functions.zsh` | functions (`hpclaude`, `apclaude`) |

To add config, drop a new numbered file in there — don't grow `.zshrc`.

Every block in `40-path.zsh` and `50-tools.zsh` is guarded, so a machine
without (say) sdkman or the Android SDK just gets a shorter `PATH` rather than
a broken shell.

## Zed

`./install.sh zed` installs Zed (via zed.dev — skipped if it's already on PATH)
and symlinks `~/.config/zed/settings.json`.

The extension list lives in `auto_install_extensions` at the top of that file,
so a fresh machine downloads the same themes and language support on first
launch — there's nothing to run by hand. To add one, install it from the
extensions panel and add its id to that block.

## Pentest

`./install.sh pentest` installs lab tooling for TryHackMe / HackTheBox. Only
use it against machines you're authorised to test.

| from | tools |
|------|-------|
| distro packages | nmap, ncat, hydra, john, hashcat, tshark, openvpn, gobuster, ffuf, masscan, whatweb, dnsenum, smbclient, onesixtyone, snmp utils, medusa, ncrack |
| git clone → `~/.local/share` | sqlmap, nikto, enum4linux, hash-identifier, commix, cewl, snmp-check |
| pipx | fierce, hashid, smbmap, wfuzz, dnsrecon, enum4linux-ng |
| user gems | wpscan |
| GitHub release binary | feroxbuster |
| built from source | crunch, nbtscan |
| asked first | Metasploit, SecLists (~1.5 GB, /usr/share/seclists), Burp Suite Community, ZAP |

Anything not from the distro lives under `~/.local` (launchers in
`~/.local/bin`), and re-running updates it. A tool that fails to install is
warned about and skipped rather than failing the module. Scan output and notes go in
`~/labs`, **not** in this repo. Keep them in their own private repo, since HTB
doesn't allow public writeups of active boxes. To connect to a lab VPN:
`sudo openvpn ~/labs/vpn/<file>.ovpn`.

## Machine-specific things

`~/.zshrc.local` is sourced last and is **not** tracked. Per-laptop paths,
work-only settings, and anything secret go there. The installer seeds it from
`modules/zsh/zshrc.local.example` on first run.

## Notes

- The `session` module installs **JetBrainsMono Nerd Font** (kitty, bar, p10k glyphs).
- Something broken after login? `Ctrl+Alt+F2` gives a plain console (only tty1 starts
  Hyprland); fix it there, or `touch ~/.config/rice/no-autostart` to stop the autostart.
- If zsh isn't your login shell: `chsh -s "$(command -v zsh)"`.
