#!/usr/bin/env bash
# Shared helpers for all rice modules.

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"

# ── output ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'; C_RED=$'\033[1;31m'; C_DIM=$'\033[2m'
else
  C_RESET=; C_BLUE=; C_GREEN=; C_YELLOW=; C_RED=; C_DIM=
fi

info()  { printf '%s==>%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%s  !%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf '%s  ✗%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
skip()  { printf '%s  ·%s %s\n' "$C_DIM"    "$C_RESET" "$*"; }
die()   { err "$*"; exit 1; }

run() {
  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: $*"
  else
    "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# confirm <prompt> — interactive y/N prompt; defaults to No (non-destructive)
# when there's no tty to ask.
confirm() {
  local prompt="$1" reply
  if [ ! -t 0 ]; then
    warn "$prompt [non-interactive, defaulting to No]"
    return 1
  fi
  read -r -p "$prompt [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── OS / package manager ─────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${ID_LIKE:-$ID}" | tr ' ' '\n' | head -1
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

RICE_OS="$(detect_os)"

pkg_manager() {
  for m in dnf pacman apt-get zypper brew; do
    have "$m" && { echo "$m"; return; }
  done
  echo ""
}

# pkg_install <pkg>...  — installs only the packages that are missing.
pkg_install() {
  local pm missing=()
  pm="$(pkg_manager)"
  [ -n "$pm" ] || { warn "no known package manager; install manually: $*"; return 0; }

  for p in "$@"; do
    pkg_is_installed "$pm" "$p" || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] && { skip "packages already present: $*"; return 0; }

  info "installing: ${missing[*]}"
  local sudo_cmd=""
  [ "$(id -u)" -ne 0 ] && [ "$pm" != "brew" ] && sudo_cmd="sudo"

  case "$pm" in
    dnf)     run $sudo_cmd dnf install -y "${missing[@]}" ;;
    pacman)  run $sudo_cmd pacman -S --needed --noconfirm "${missing[@]}" ;;
    apt-get) run $sudo_cmd apt-get update -qq && run $sudo_cmd apt-get install -y "${missing[@]}" ;;
    zypper)  run $sudo_cmd zypper install -y "${missing[@]}" ;;
    brew)    run brew install "${missing[@]}" ;;
  esac
}

pkg_is_installed() {
  local pm="$1" p="$2"
  case "$pm" in
    dnf|zypper) rpm -q "$p" >/dev/null 2>&1 ;;
    pacman)     pacman -Qi "$p" >/dev/null 2>&1 ;;
    apt-get)    dpkg -s "$p" >/dev/null 2>&1 ;;
    brew)       brew list --formula "$p" >/dev/null 2>&1 ;;
    *)          return 1 ;;
  esac
}

# ── linking (via GNU Stow) ───────────────────────────────────────────────────
ensure_stow() {
  have stow && return 0
  if [ "${SKIP_DEPS:-0}" = "1" ]; then
    die "stow is required to link dotfiles; install it or drop --no-deps"
  fi
  info "installing stow (required to link dotfiles)"
  pkg_install stow
}

# link_file <source> <target> — symlink one file. Prompts before clobbering
# anything already there; declining leaves it untouched. No backups are made.
link_file() {
  local src="$1" dst="$2"
  [ -e "$src" ] || die "missing source: $src"

  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    skip "$dst (already linked)"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      warn "$dst already exists — would prompt to overwrite"
      return 0
    fi
    if ! confirm "$dst already exists. Overwrite it (no backup)?"; then
      skip "leaving $dst untouched"
      return 0
    fi
    run rm -rf "$dst"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  ok "$dst -> $src"
}

# moves any files still sitting in hide_dir back into root at their original
# relative path (normal cleanup, or recovery after a crashed run), then
# removes hide_dir.
_rice_restore_hidden() {
  local root="$1" hide_dir="$2" f rel
  [ -d "$hide_dir" ] || return 0
  while IFS= read -r -d '' f; do
    rel="${f#"$hide_dir"/}"
    mkdir -p "$(dirname "$root/$rel")"
    mv "$f" "$root/$rel"
  done < <(find "$hide_dir" -type f -print0 2>/dev/null)
  rm -rf "$hide_dir"
}

# extracts the conflicting target path from one line of `stow -n` output,
# across the several message shapes Stow.pm can produce. Echoes nothing if
# the line isn't a conflict line.
_rice_stow_conflict_path() {
  local line="$1"
  if [[ "$line" =~ existing\ target\ is\ not\ owned\ by\ stow:\ (.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$line" =~ existing\ target\ is\ stowed\ to\ a\ different\ package:\ (.+)\ =\> ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$line" =~ cannot\ stow\ .*\ over\ existing\ directory\ target\ (.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$line" =~ cannot\ stow\ .*\ over\ existing\ target\ (.+)\ since\  ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  fi
}

# link_tree <module-home-dir> — stows the tree into $HOME with GNU Stow
# (module-home-dir must be named "home" inside its module, e.g. modules/zsh/home).
# Any real file/dir already at a target path triggers a per-file prompt;
# declining leaves that one file unmanaged and unlinked. No backups are made.
link_tree() {
  local root="$1"
  [ -d "$root" ] || return 0
  ensure_stow

  local stow_dir pkg
  stow_dir="$(cd "$root/.." && pwd)"
  pkg="$(basename "$root")"

  # Skipped files are moved out of the package tree entirely (not just
  # renamed in place) so Stow can't find and link them under a new name.
  local hide_dir
  hide_dir="$(mktemp -d "${TMPDIR:-/tmp}/rice-hide.XXXXXX")"
  trap "_rice_restore_hidden '$root' '$hide_dir'" RETURN EXIT

  local out line rel
  out="$(stow -n -d "$stow_dir" -t "$HOME" "$pkg" 2>&1 >/dev/null || true)"
  while IFS= read -r line; do
    rel="$(_rice_stow_conflict_path "$line")"
    [ -n "$rel" ] || continue
    local target="$HOME/$rel" src="$root/$rel"
    if [ "$DRY_RUN" = "1" ]; then
      warn "$target already exists — would prompt to overwrite"
      continue
    fi
    if confirm "$target already exists and isn't managed by stow. Overwrite it (no backup)?"; then
      run rm -rf "$target"
    else
      skip "leaving $target untouched (not linking $rel)"
      mkdir -p "$(dirname "$hide_dir/$rel")"
      mv "$src" "$hide_dir/$rel"
    fi
  done <<< "$out"

  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: stow -d $stow_dir -t $HOME $pkg"
  else
    run stow -d "$stow_dir" -t "$HOME" "$pkg"
    ok "linked $pkg -> $HOME"
  fi
}

# clone_or_update <repo-url> <dest> [--depth N]
clone_or_update() {
  local url="$1" dest="$2"; shift 2
  if [ -d "$dest/.git" ]; then
    skip "$dest present (git pull --ff-only)"
    run git -C "$dest" pull --ff-only --quiet || warn "could not update $dest"
  else
    info "cloning $url -> $dest"
    run git clone --quiet "$@" "$url" "$dest"
    ok "cloned $(basename "$dest")"
  fi
}
