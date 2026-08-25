# Adding a module

A module is a directory under `modules/` with two pieces:

```
modules/<name>/
├── module.sh      # install steps (deps, clones, links)  — required
└── home/          # tree mirrored into $HOME, file-by-file symlinks
    └── .config/<name>/...
```

`install.sh` sources `module.sh` in a subshell with `lib/common.sh` already
loaded and these variables set:

| variable      | meaning                                    |
|---------------|--------------------------------------------|
| `$RICE_DIR`   | repo root                                   |
| `$MODULE_DIR` | this module's directory                     |
| `$DRY_RUN`    | `1` when `--dry-run` was passed             |
| `$SKIP_DEPS`  | `1` when `--no-deps` was passed             |
| `$RICE_OS`    | `fedora`, `arch`, `debian`, `macos`, …      |

Helpers available from `lib/common.sh`:

- `info` / `ok` / `warn` / `err` / `skip` / `die` — consistent output
- `run <cmd>` — respects `--dry-run`; use it for anything that mutates
- `have <cmd>` — is a command on PATH
- `pkg_install <pkg>...` — installs only what's missing, via dnf/pacman/apt/zypper/brew
- `link_file <src> <dst>` — symlink one file; prompts before overwriting a
  real file already there (no backup — decline to leave it untouched)
- `link_tree <dir>` — stow `dir` (must be named `home`) into `$HOME` via GNU
  Stow; same per-file overwrite prompt for anything Stow can't fold in
- `clone_or_update <url> <dest> [git-args]` — idempotent clone

A minimal module:

```sh
#!/usr/bin/env bash
MOD="${MODULE_DIR}"

[ "${SKIP_DEPS:-0}" = "1" ] || pkg_install hyprland waybar

link_tree "$MOD/home"
```

That's it — `./install.sh` picks it up automatically. Keep every step
idempotent: running the installer twice must be a no-op.
