#!/usr/bin/env bash
# rice_check — verifies the desktop actually picked up rice: Hyprland reads the Lua config with
# rice's keybinds, kitty/bar/lock files are linked, the shell runs without errors in rice files.
# Prints one line per check with a fix hint, returns non-zero if anything failed.

rice_check() {
  local fails=0
  pass() { printf '%s  ✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
  fail() {
    printf '%s  ✗%s %s\n' "$C_RED" "$C_RESET" "$1"
    [ -n "${2:-}" ] && printf '      %s→ %s%s\n' "$C_DIM" "$2" "$C_RESET"
    fails=$((fails + 1))
  }
  linked() { [ -L "$1" ] && [[ "$(readlink -f "$1")" == "$RICE_DIR"/* ]]; }

  info "checking the rice setup"

  # Hyprland
  local hv
  hv="$(Hyprland --version 2>/dev/null | grep -oE 'Hyprland [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')"
  if [ -z "$hv" ]; then
    fail "Hyprland is not installed" "./install.sh hyprland"
  elif [ "$(printf '%s\n' "$RICE_MIN_HYPRLAND" "$hv" | sort -V | head -1)" != "$RICE_MIN_HYPRLAND" ]; then
    fail "Hyprland $hv is too old for the Lua config (needs $RICE_MIN_HYPRLAND+)" "./install.sh hyprland  (upgrades it)"
  else
    pass "Hyprland $hv"
  fi

  if linked "$HOME/.config/hypr/hyprland.lua" && linked "$HOME/.config/hypr/hyprland/keybinds.lua"; then
    pass "Hyprland config linked"
  else
    fail "Hyprland config not linked" "./install.sh hyprland"
  fi

  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then
    local errs
    errs="$(hyprctl configerrors 2>/dev/null | grep -v '^\s*$' || true)"
    if [ -n "$errs" ]; then
      fail "Hyprland config errors: $(echo "$errs" | head -1)" "hyprctl configerrors"
    elif hyprctl binds -j 2>/dev/null | grep -q 'Terminal (new window)'; then
      pass "rice keybinds active (SUPER+Enter → kitty tab)"
    else
      fail "Hyprland is running but not with rice's keybinds" "log out and back in (or: hyprctl reload)"
    fi
  else
    skip "not inside Hyprland — skipping live keybind check"
  fi

  # kitty
  if linked "$HOME/.config/kitty/kitty.conf"; then
    pass "kitty config linked (tabs)"
  else
    fail "kitty config not linked" "./install.sh kitty"
  fi

  # quickshell (bar + lock)
  local ii="$HOME/.config/quickshell/ii" f missing=()
  if [ ! -f "$ii/shell.qml" ]; then
    fail "end-4's shell isn't installed ($ii)" "./install.sh base"
  else
    local ref=""
    [ -f "$ii/.rice-end4-ref" ] && ref="$(cat "$ii/.rice-end4-ref")"
    if [ "$ref" = "$RICE_END4_REF" ]; then
      pass "end-4 shell at the version rice is built on ($RICE_END4_REF)"
    else
      fail "end-4 shell version unknown or different from $RICE_END4_REF — rice's bar may not load" "./install.sh base"
    fi
    for f in modules/ii/bar/BarContent.qml modules/ii/lock/LockSurface.qml services/NepaliDate.qml; do
      linked "$ii/$f" || missing+=("$f")
    done
    if [ ${#missing[@]} -eq 0 ]; then
      pass "bar and lock screen files linked"
    else
      fail "not linked: ${missing[*]}" "./install.sh quickshell"
    fi
  fi

  if pgrep -x qs >/dev/null; then
    local qerr
    qerr="$(qs log -c ii 2>/dev/null | grep -E 'ERROR|caused by' | grep -E 'BarContent|ClockWidget|BatteryIndicator|NetworkIndicator|LockSurface|NepaliDate|IllogicalImpulseFamily' | tail -3 || true)"
    if [ -n "$qerr" ]; then
      fail "quickshell reports errors in rice files:" "$(echo "$qerr" | sed 's/\x1b\[[0-9;]*m//g' | head -1)"
    else
      pass "quickshell running, no errors in rice files"
    fi
  else
    skip "quickshell not running — skipping live check (it starts with Hyprland)"
  fi

  echo
  if [ "$fails" -eq 0 ]; then
    ok "everything looks good"
  else
    warn "$fails check(s) failed — run the suggested command, or paste this output"
  fi
  [ "$fails" -eq 0 ]
}
