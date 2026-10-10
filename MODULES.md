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
| `$RICE_OS`    | `fedora`, `arch` or `opensuse`              |
| `$SUDO`       | `sudo`, or empty when running as root       |

Helpers available from `lib/common.sh`:

- `info` / `ok` / `warn` / `err` / `skip` / `die` — consistent output
- `run <cmd>` — respects `--dry-run`; use it for anything that mutates
- `have <cmd>` — is a command on PATH
- `pkg_install <pkg>...` — installs only what's missing via dnf/pacman/zypper;
  a package that can't be installed is warned about, never fatal
- `pkg_try <pkg>...` — same, but returns non-zero on failure (for fallbacks)
- `copr_enable <owner/project>` — Fedora only; no-op if already enabled
- `link_file <src> <dst>` — symlink one file; anything already there is moved
  to `<dst>.rice-bak` first; already-linked files are skipped
- `link_tree <dir>` — `link_file` every file under `dir` into `$HOME`
- `clone_or_update <url> <dest> [git-args]` — idempotent clone

A minimal module:

```sh
#!/usr/bin/env bash
MOD="${MODULE_DIR}"

[ "${SKIP_DEPS:-0}" = "1" ] || pkg_install hyprland waybar

link_tree "$MOD/home"
```

That's it — `./install.sh` picks it up automatically. To make a module
opt-in, add an empty `.optional` file next to its `module.sh`: a bare
`./install.sh` then asks before running it, and `./install.sh <name>` still
installs it directly. Keep every step
idempotent: running the installer twice must be a no-op.
