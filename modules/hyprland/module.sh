#!/usr/bin/env bash
# hyprland module: Hyprland (Lua config, end-4 illogical-impulse layout) plus
# hyprlock/hypridle. Keybinds live in .config/hypr/hyprland/keybinds.lua;
# personal overrides go in .config/hypr/custom/*.lua.

MOD="${MODULE_DIR:-$RICE_DIR/modules/hyprland}"

# ── 1. hyprland itself ───────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
elif [ "$RICE_OS" = "macos" ]; then
  skip "hyprland is Linux-only"
  return 0 2>/dev/null || exit 0
else
  pkg_install hyprland hyprlock hypridle
fi

# The binds call into quickshell (the "ii" shell), fuzzel, hyprpicker,
# playerctl, wpctl, etc. Warn rather than install — the shell is its own setup.
have qs || warn "quickshell (qs) not found — shell keybinds (SUPER, SUPER+Tab, …) won't do anything"

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"
