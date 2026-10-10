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

  # An older Hyprland silently ignores hyprland.lua and falls back to a legacy config,
  # so none of rice's keybinds load. Upgrade it if needed.
  hv="$(Hyprland --version 2>/dev/null | grep -oE 'Hyprland [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' || true)"
  if [ -n "$hv" ] && [ "$(printf '%s\n' "$RICE_MIN_HYPRLAND" "$hv" | sort -V | head -1)" != "$RICE_MIN_HYPRLAND" ]; then
    info "Hyprland $hv is too old for the Lua config — upgrading to $RICE_MIN_HYPRLAND+"
    case "$RICE_OS" in
    fedora) run $SUDO dnf upgrade -y --refresh hyprland hyprlock hypridle || true ;;
    arch) run $SUDO pacman -Syu --needed --noconfirm hyprland hyprlock hypridle || true ;;
    opensuse) run $SUDO zypper --non-interactive update hyprland hyprlock hypridle || true ;;
    esac
    warn "log out and back in so the new Hyprland starts"
  fi
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
