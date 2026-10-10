#!/usr/bin/env bash
#
#   rice — dotfiles bootstrap for Fedora, Arch and openSUSE
#
#   Usage:
#     ./install.sh                 install every module in modules/ (asks about
#                                  optional ones, e.g. pentest)
#     ./install.sh zsh             install only the named module(s)
#     ./install.sh --list          list available modules
#     ./install.sh --dry-run zsh   show what would happen, change nothing
#     ./install.sh --no-deps zsh   link configs only, skip package installs
#     ./install.sh --check         check that everything is installed and working
#
#   Safe to re-run: anything already installed or linked is skipped, and files
#   that would be replaced are backed up to <file>.rice-bak first.
#   Add a new module by creating modules/<name>/module.sh (see modules/zsh).
#   Drop an empty .optional file in a module to make it opt-in.

set -euo pipefail

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RICE_DIR
# shellcheck source=lib/common.sh
. "$RICE_DIR/lib/common.sh"

MODULES_DIR="$RICE_DIR/modules"
SKIP_DEPS=0

list_modules() {
  find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

# optional modules (marked with a .optional file) are skipped by a bare
# ./install.sh unless you say yes at the prompt; naming one always installs it.
is_optional() { [ -f "$MODULES_DIR/$1/.optional" ]; }

usage() { sed -n '2,20p' "$0" | sed 's/^#//;s/^ //'; }

# optional_needed <module> — 0 if the module still has something to install. A module can ship
# a status.sh defining module_status (prints what it installs; returns 0 when all present).
optional_needed() {
  local status="$MODULES_DIR/$1/status.sh"
  [ -f "$status" ] || return 0
  # shellcheck disable=SC1090
  (. "$status" && ! module_status)
}

targets=()
while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -l | --list)
    while IFS= read -r m; do
      if is_optional "$m"; then echo "$m (optional)"; else echo "$m"; fi
    done < <(list_modules)
    exit 0
    ;;
  -n | --dry-run)
    DRY_RUN=1
    export DRY_RUN
    ;;
  --no-deps) SKIP_DEPS=1 ;;
  --check)
    # shellcheck source=lib/check.sh
    . "$RICE_DIR/lib/check.sh"
    rice_check
    exit $?
    ;;
  -*) die "unknown option: $1" ;;
  *) targets+=("$1") ;;
  esac
  shift
done
export SKIP_DEPS

if [ ${#targets[@]} -eq 0 ]; then
  # read the list up front so confirm's prompt still gets the terminal on stdin
  mapfile -t all_modules < <(list_modules)
  for m in "${all_modules[@]}"; do
    if ! is_optional "$m"; then
      targets+=("$m")
    elif ! optional_needed "$m"; then
      skip "optional module $m already installed (run ./install.sh $m to update it)"
    elif confirm "Install optional module '$m'?"; then
      targets+=("$m")
    else
      skip "skipping optional module $m (run ./install.sh $m to add it later)"
    fi
  done
fi
[ ${#targets[@]} -eq 0 ] && die "no modules found in $MODULES_DIR"

# base (end-4's shell) goes first: the hyprland, kitty and quickshell modules layer on top of it
ordered=()
for m in "${targets[@]}"; do [ "$m" = "base" ] && ordered+=("$m"); done
for m in "${targets[@]}"; do [ "$m" != "base" ] && ordered+=("$m"); done
targets=("${ordered[@]}")

case "$RICE_OS" in
fedora | arch | opensuse) ;;
*) die "unsupported system — rice supports Fedora, Arch and openSUSE only" ;;
esac

[ "$DRY_RUN" = "1" ] && warn "dry run — nothing will be changed"
info "rice: $RICE_DIR ($RICE_OS)"
info "modules: ${targets[*]}"

failed=()
for m in "${targets[@]}"; do
  mod="$MODULES_DIR/$m"
  [ -d "$mod" ] || {
    err "no such module: $m"
    failed+=("$m")
    continue
  }
  [ -f "$mod/module.sh" ] || {
    err "$m has no module.sh"
    failed+=("$m")
    continue
  }

  echo
  info "── module: $m ──"
  MODULE_DIR="$mod"
  export MODULE_DIR
  # Each module runs in a subshell so one failure can't poison the rest.
  if (. "$mod/module.sh"); then
    ok "module $m done"
  else
    err "module $m failed"
    failed+=("$m")
  fi
done

echo
if [ ${#failed[@]} -gt 0 ]; then
  err "failed: ${failed[*]}"
  exit 1
fi
ok "all done"

# Verify the result so problems show up here, not after a re-login.
if [ "$DRY_RUN" != "1" ]; then
  # shellcheck source=lib/check.sh
  . "$RICE_DIR/lib/check.sh"
  echo
  rice_check || true
fi
