#!/usr/bin/env bash
# Shared helpers for all rice modules. Supports Fedora (dnf), Arch (pacman) and openSUSE (zypper).
# Everything here is idempotent: re-running skips what is already in place.

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"

# rice's bar/lock files are full copies of end-4 files from this commit, and the Lua Hyprland
# config needs at least this Hyprland. base/hyprland enforce these; lib/check.sh verifies them.
RICE_END4_REF="d192a25f"
RICE_MIN_HYPRLAND="0.55.0"

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

# confirm <prompt> — interactive y/N prompt; defaults to No when there's no tty to ask.
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

# ── distro / package manager ─────────────────────────────────────────────────
# RICE_OS is one of: fedora, arch, opensuse. Anything else is rejected by install.sh.
detect_os() {
  [ -r /etc/os-release ] || { echo "unknown"; return; }
  local id like
  id="$(. /etc/os-release && echo "${ID:-}")"
  like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
  case " $id $like " in
    *" fedora "*) echo "fedora" ;;
    *" arch "*) echo "arch" ;;
    *" opensuse"* | *" suse "*) echo "opensuse" ;;
    *) echo "unknown" ;;
  esac
}

RICE_OS="$(detect_os)"

pkg_manager() {
  case "$RICE_OS" in
    fedora) echo "dnf" ;;
    arch) echo "pacman" ;;
    opensuse) echo "zypper" ;;
    *) echo "" ;;
  esac
}

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

pkg_is_installed() {
  case "$(pkg_manager)" in
    dnf | zypper) rpm -q --whatprovides "$1" >/dev/null 2>&1 ;;
    pacman) pacman -Qi "$1" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

_pkg_install_raw() {
  case "$(pkg_manager)" in
    dnf) run $SUDO dnf install -y "$@" ;;
    pacman) run $SUDO pacman -S --needed --noconfirm "$@" ;;
    zypper) run $SUDO zypper --non-interactive install "$@" ;;
  esac
}

# pkg_try <pkg>... — installs only what is missing. If the batch fails (e.g. one name doesn't exist
# on this distro), retries one by one so the rest still land. Returns non-zero if anything is
# still missing — use it when there is a fallback to try.
pkg_try() {
  local missing=() p failed=()
  for p in "$@"; do
    pkg_is_installed "$p" || missing+=("$p")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    skip "packages already present: $*"
    return 0
  fi
  info "installing: ${missing[*]}"
  _pkg_install_raw "${missing[@]}" && return 0
  for p in "${missing[@]}"; do
    pkg_is_installed "$p" || _pkg_install_raw "$p" || failed+=("$p")
  done
  if [ ${#failed[@]} -gt 0 ]; then
    warn "could not install: ${failed[*]}"
    return 1
  fi
}

# pkg_install <pkg>... — like pkg_try, but a failure only warns, so one missing package never
# stops the rest of a module.
pkg_install() {
  pkg_try "$@" || true
}

# copr_enable <owner/project> — Fedora only; no-op if already enabled.
copr_enable() {
  [ "$RICE_OS" = "fedora" ] || return 0
  local repo="$1" file="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${1%%/*}:${1##*/}.repo"
  if [ -f "$file" ]; then
    skip "copr $repo already enabled"
    return 0
  fi
  pkg_install dnf-plugins-core
  run $SUDO dnf copr enable -y "$repo"
}

# ── linking ──────────────────────────────────────────────────────────────────
# link_file <source> <target> — symlink one file. Anything already at the target that isn't
# this link is moved aside to <target>.rice-bak first (once; a second backup gets a timestamp),
# so nothing is lost and no question is asked.
link_file() {
  local src="$1" dst="$2"
  [ -e "$src" ] || die "missing source: $src"

  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    skip "${dst/#$HOME/\~} (already linked)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      skip "would back up ${dst/#$HOME/\~} and link it"
    else
      skip "would link ${dst/#$HOME/\~}"
    fi
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="$dst.rice-bak"
    [ -e "$bak" ] || [ -L "$bak" ] && bak="$dst.rice-bak.$(date +%Y%m%d%H%M%S)"
    run mv "$dst" "$bak"
    warn "backed up ${dst/#$HOME/\~} -> ${bak/#$HOME/\~}"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  ok "${dst/#$HOME/\~} -> ${src/#$RICE_DIR\//rice/}"
}

# link_tree <module-home-dir> — links every file under it into $HOME at the same relative path.
# Directories are created as real directories, so rice files sit next to other tools' files
# (e.g. our bar files inside end-4's quickshell config).
link_tree() {
  local root="$1" f rel
  [ -d "$root" ] || return 0
  while IFS= read -r -d '' f; do
    rel="${f#"$root"/}"
    link_file "$f" "$HOME/$rel"
  done < <(find "$root" \( -type f -o -type l \) -print0 | sort -z)
}

# clone_or_update <repo-url> <dest> [git clone args...]
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

# ── picking ──────────────────────────────────────────────────────────────────
# pick_missing <preset-var> <title> <is-installed-fn> "name|label"...
# Lists what's already installed, offers only the rest as a numbered list, and sets PICKED to
# the chosen names (space-separated). If the variable named <preset-var> is set ("all" or a
# list of names) it's used instead of asking. No terminal and no preset → picks nothing.
pick_missing() {
  local preset="${!1:-}" var="$1" title="$2" check="$3" entry reply n i
  shift 3
  local installed=() offered=()
  PICKED=""
  for entry in "$@"; do
    if "$check" "${entry%%|*}"; then installed+=("${entry#*|}"); else offered+=("$entry"); fi
  done
  if [ ${#installed[@]} -gt 0 ]; then
    skip "already installed: $(printf '%s, ' "${installed[@]}" | sed 's/, $//')"
  fi
  if [ ${#offered[@]} -eq 0 ]; then
    ok "everything already installed"
    return 0
  fi

  if [ -n "$preset" ]; then
    reply="$preset"
  elif [ -t 0 ]; then
    echo
    info "$title you don't have yet:"
    i=1
    for entry in "${offered[@]}"; do
      printf '   %d) %s\n' "$i" "${entry#*|}"
      i=$((i + 1))
    done
    read -r -p "Install which? numbers like '1 3', 'a' for all, Enter for none: " reply
  else
    warn "no terminal to ask — skipping (set $var=\"all\" or a list of names)"
    return 0
  fi

  case "$reply" in
  a | A | all) for entry in "${offered[@]}"; do PICKED+="${entry%%|*} "; done ;;
  *)
    for n in $reply; do
      if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#offered[@]} ]; then
        PICKED+="${offered[$((n - 1))]%%|*} "
      else
        # a preset may name items directly; keep only ones on offer
        for entry in "${offered[@]}"; do [ "${entry%%|*}" = "$n" ] && PICKED+="$n "; done
      fi
    done
    ;;
  esac
  PICKED="${PICKED% }"
  [ -n "$PICKED" ] || skip "nothing selected"
}
