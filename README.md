# rice

My dotfiles. One command to get a new laptop to the same shell I have here.

```sh
git clone git@github.com:parajuliaashutosh/rice.git ~/rice
cd ~/rice && ./install.sh
exec zsh
```

## What it does

`install.sh` walks `modules/`, and for each module installs its dependencies
and symlinks its config into `$HOME` using [GNU Stow](https://www.gnu.org/software/stow/).
If a real file already sits where a symlink needs to go, it asks before
touching it — decline and that one file is left alone, unmanaged; accept and
it's overwritten with no backup. Re-running it is safe — every step is
idempotent.

```sh
./install.sh              # all modules
./install.sh zsh          # just one
./install.sh --list       # what's available
./install.sh --dry-run    # show the plan, change nothing
./install.sh --no-deps    # link configs only, skip package installs
```

## Modules

| module | what it sets up |
|--------|-----------------|
| `zsh`  | oh-my-zsh, powerlevel10k, autosuggestions, syntax highlighting, my shell config |
| `zed`  | the Zed editor and its settings (extensions install themselves on first launch) |
| `hyprland` | Hyprland + hyprlock/hypridle config, including all keybinds |

Future: `waybar`, `nvim`, `git`, `kitty` — see [MODULES.md](MODULES.md).

## Layout

```
rice/
├── install.sh              entry point
├── lib/common.sh           logging, symlinking, package install, git clone
└── modules/
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
    └── hyprland/
        ├── module.sh
        └── home/.config/hypr/   (keybinds in hyprland/keybinds.lua)
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

`./install.sh zed` installs Zed (via zed.dev on Linux, `brew --cask` on macOS —
skipped if it's already on PATH) and symlinks `~/.config/zed/settings.json`.

The extension list lives in `auto_install_extensions` at the top of that file,
so a fresh machine downloads the same themes and language support on first
launch — there's nothing to run by hand. To add one, install it from the
extensions panel and add its id to that block.

## Machine-specific things

`~/.zshrc.local` is sourced last and is **not** tracked. Per-laptop paths,
work-only settings, and anything secret go there. The installer seeds it from
`modules/zsh/zshrc.local.example` on first run.

## Notes

- The p10k prompt needs a Nerd Font — install **MesloLGS NF** and set it in
  your terminal.
- If zsh isn't your login shell: `chsh -s "$(command -v zsh)"`.
