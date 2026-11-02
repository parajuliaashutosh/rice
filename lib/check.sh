#!/usr/bin/env bash
# rice_check — verifies the desktop actually picked up rice: Hyprland reads the Lua config with
# rice's keybinds, kitty/bar/launcher/lock files are linked, the bar runs, login and swap are set up.
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

  # nvim (picked in the apps module)
  if have nvim; then
    if linked "$HOME/.config/nvim/init.lua"; then
      pass "nvim config linked (LazyVim)"
    else
      fail "nvim config not linked" "RICE_APPS=nvim ./install.sh apps"
    fi
  fi

  # bar, launcher, notifications, wallpaper colors
  local f missing=()
  for f in waybar/config.jsonc waybar/style.css fuzzel/fuzzel.ini matugen/config.toml \
    hypr/hyprland/scripts/wallpaper-set.sh hypr/hyprland/scripts/window-switcher.sh; do
    linked "$HOME/.config/$f" || missing+=("$f")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    pass "bar, launcher and wallpaper configs linked"
  else
    fail "not linked: ${missing[*]}" "./install.sh waybar fuzzel wallpaper hyprland"
  fi
  missing=()
  for f in hypr/hyprland/colors.lua hypr/hyprlock/colors.conf waybar/colors.css fuzzel/colors.ini mako/config; do
    [ -f "$HOME/.config/$f" ] || missing+=("$f")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    pass "color files present (matugen or fallback)"
  else
    fail "missing color files: ${missing[*]}" "./install.sh hyprland waybar fuzzel mako wallpaper"
  fi
  local tool
  missing=()
  for tool in waybar fuzzel mako swaybg matugen hyprlock hypridle cliphist; do
    have "$tool" || missing+=("$tool")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    pass "desktop tools installed"
  else
    fail "not installed: ${missing[*]}" "./install.sh"
  fi
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    missing=()
    for tool in waybar mako swaybg hypridle; do pgrep -x "$tool" >/dev/null || missing+=("$tool"); done
    if [ ${#missing[@]} -eq 0 ]; then
      pass "waybar, mako, swaybg and hypridle running"
    else
      fail "not running: ${missing[*]}" "SUPER+Escape restarts bar + notifications; or log out and back in"
    fi
  fi

  # login
  if grep -qF "rice/hyprland-autostart.sh" "$HOME/.bash_profile" "$HOME/.zprofile" 2>/dev/null; then
    pass "logging in on tty1 starts Hyprland"
  else
    fail "tty1 autostart not set up" "./install.sh session"
  fi

  # swap
  if swapon --show=NAME --noheadings 2>/dev/null | grep -q '^/dev/zram'; then
    pass "zram swap active"
  else
    fail "no zram swap" "./install.sh swap  (or reboot)"
  fi
  if [ "${RICE_SWAPFILE_GB:-20}" = "0" ]; then
    skip "swapfile disabled (RICE_SWAPFILE_GB=0)"
  elif swapon --show=NAME --noheadings 2>/dev/null | grep -qx /swap/swapfile; then
    pass "swapfile /swap/swapfile active"
  else
    fail "/swap/swapfile not active" "./install.sh swap"
  fi

  echo
  if [ "$fails" -eq 0 ]; then
    ok "everything looks good"
  else
    warn "$fails check(s) failed — run the suggested command, or paste this output"
  fi
  [ "$fails" -eq 0 ]
}
