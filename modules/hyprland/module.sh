#!/usr/bin/env bash
# hyprland module: Hyprland (Lua config, same keybinds/monitor setup as main) plus hyprlock,
# hypridle, the Hyprland portal and polkit agent. Keybinds live in .config/hypr/hyprland/keybinds.lua;
# personal overrides go in .config/hypr/custom/*.lua.
# minimal branch: no quickshell. The bar is waybar, the launcher fuzzel, notifications mako
# (their own modules); the binds that used quickshell call scripts in hypr/hyprland/scripts.

MOD="${MODULE_DIR:-$RICE_DIR/modules/hyprland}"

# ── 1. hyprland itself ───────────────────────────────────────────────────────
# Fedora's own repos don't carry a Hyprland new enough for the Lua config; sdegler/hyprland
# is the COPR for it. Arch and openSUSE Tumbleweed ship it in their main repos.
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  copr_enable sdegler/hyprland
  pkg_install hyprland hyprlock hypridle hyprpicker xdg-desktop-portal-hyprland hyprpolkitagent \
    jq grim slurp wl-clipboard swappy wf-recorder brightnessctl playerctl libnotify curl

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

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"

# colors.lua / hyprlock colors.conf are written by matugen (wallpaper module) in place, so they
# are real files, not links. Links left over from older rice versions point at nothing, so drop
# them; then put a fallback copy where none exists so the config loads before any wallpaper.
for pair in "colors.lua:hypr/hyprland/colors.lua" "hyprlock-colors.conf:hypr/hyprlock/colors.conf"; do
  src="$MOD/fallback/${pair%%:*}" dst="$HOME/.config/${pair#*:}"
  [ -L "$dst" ] && [ ! -e "$dst" ] && run rm "$dst"
  if [ -e "$dst" ]; then
    skip "${dst/#$HOME/\~} present"
  else
    run mkdir -p "$(dirname "$dst")"
    run cp "$src" "$dst" && ok "${dst/#$HOME/\~} (fallback colors until the first wallpaper)"
  fi
done

# ── 3. pick up the changes in a running session ──────────────────────────────
if [ "$DRY_RUN" != "1" ] && [ "${RICE_NO_RELOAD:-0}" != "1" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then
  hyprctl reload >/dev/null && ok "reloaded Hyprland"
  # hypridle only reads its config at startup, so restart it to pick up lock_cmd changes
  if pkill -x hypridle; then setsid -f hypridle >/dev/null 2>&1 && ok "restarted hypridle"; fi
fi
