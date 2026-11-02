#!/usr/bin/env bash
# waybar module: the bar (replaces the quickshell bar from main). Same layout:
#   Fedora logo + workspaces | weather, ↓/↑ net | clock • date • Nepali (BS) date | battery,
#   CPU/RAM/swap, color picker, brightness, volume, tray (wifi + bluetooth applets)
# Colors: colors.css is written by matugen (wallpaper module); a fallback copy is installed first.

MOD="${MODULE_DIR:-$RICE_DIR/modules/waybar}"

# ── 1. waybar ────────────────────────────────────────────────────────────────
# Hyprland's Lua config rejects old-style "dispatch workspace 3", which is what Waybar 0.15.0
# sends. The git build in the sdegler/hyprland COPR (enabled by the hyprland module) has the
# Lua dispatch fix; Fedora's own 0.15.0 doesn't, so swap that one out.
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  copr_enable sdegler/hyprland
  pkg_install waybar jq curl awk pavucontrol
  if [ "$RICE_OS" = "fedora" ] && pkg_is_installed waybar; then
    wv="$(rpm -q --qf '%{VERSION}' waybar 2>/dev/null)"
    if [[ "$wv" != *git* ]] && [[ "$wv" != *^* ]]; then
      info "waybar $wv can't switch workspaces under the Lua config — switching to the COPR build"
      run $SUDO dnf distro-sync -y --refresh waybar || warn "could not update waybar; workspace clicks may not work"
    fi
  fi
fi

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"

dst="$HOME/.config/waybar/colors.css"
if [ -e "$dst" ] && [ ! -L "$dst" ]; then
  skip "~/.config/waybar/colors.css present"
else
  [ -L "$dst" ] && run rm "$dst"
  run cp "$MOD/fallback/colors.css" "$dst" && ok "~/.config/waybar/colors.css (fallback until the first wallpaper)"
fi

# ── 3. pick up the changes in a running session ──────────────────────────────
if [ "$DRY_RUN" != "1" ] && [ "${RICE_NO_RELOAD:-0}" != "1" ] && pgrep -x waybar >/dev/null; then
  pkill -SIGUSR2 -x waybar && ok "reloaded waybar"
fi
