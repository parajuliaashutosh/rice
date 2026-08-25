#!/usr/bin/env bash
# Shared helpers for all rice modules.

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.rice-backup/$(date +%Y%m%d-%H%M%S)}"
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

# ── linking ──────────────────────────────────────────────────────────────────
backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_DIR/$rel"
  run mkdir -p "$(dirname "$dest")"
  run mv "$target" "$dest"
  warn "backed up $target -> $dest"
}

# link_file <source> <target>
link_file() {
  local src="$1" dst="$2"
  [ -e "$src" ] || die "missing source: $src"

  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    skip "$dst (already linked)"
    return 0
  fi
  backup "$dst"
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  ok "$dst -> $src"
}

# link_tree <module-home-dir> — mirrors the tree into $HOME, linking leaf files.
# Directories are created for real so unmanaged files can live beside managed ones.
link_tree() {
  local root="$1"
  [ -d "$root" ] || return 0
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$root"/}"
    link_file "$f" "$HOME/$rel"
  done < <(find "$root" -type f -print0)
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
