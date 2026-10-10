#!/usr/bin/env bash
# hyprland module: Hyprland (Lua config, end-4 illogical-impulse layout) plus
# hyprlock/hypridle. Keybinds live in .config/hypr/hyprland/keybinds.lua;
# personal overrides go in .config/hypr/custom/*.lua.

MOD="${MODULE_DIR:-$RICE_DIR/modules/hyprland}"

# ── 1. hyprland itself ───────────────────────────────────────────────────────
# Fedora's own repos don't carry a Hyprland new enough for the Lua config; sdegler/hyprland
# is the COPR end-4 uses. Arch and openSUSE Tumbleweed ship it in their main repos.
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  copr_enable sdegler/hyprland
  pkg_install hyprland hyprlock hypridle jq fuzzel
fi

# The binds call into quickshell (the "ii" shell), fuzzel, hyprpicker,
# playerctl, wpctl, etc. Warn rather than install — the shell is its own setup.
have qs || warn "quickshell (qs) not found — shell keybinds (SUPER, SUPER+Tab, …) won't do anything"

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"

# ── 3. pick up the changes in a running session ──────────────────────────────
if [ "$DRY_RUN" != "1" ] && [ "${RICE_NO_RELOAD:-0}" != "1" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then
  hyprctl reload >/dev/null && ok "reloaded Hyprland"
fi
