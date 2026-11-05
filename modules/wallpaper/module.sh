#!/usr/bin/env bash
# wallpaper module: wallpaper (swaybg) + colors from it (matugen), replacing quickshell's
# wallpaper/theming. Same wallhaven list as main (~/.config/hypr/wallpapers.txt):
# wallpaper-rotate.sh downloads them to ~/Pictures/Wallpapers/rotation and moves to the next
# one on every lock. CTRL+SUPER+T picks one, CTRL+SUPER+ALT+T a random one,
# CTRL+SUPER+SHIFT+D toggles dark/light colors.
# matugen rewrites: hypr colors.lua, hyprlock colors.conf, waybar colors.css, fuzzel colors.ini,
# mako config. The other modules install fallback copies, so nothing breaks before this runs.

MOD="${MODULE_DIR:-$RICE_DIR/modules/wallpaper}"
SCRIPTS="$HOME/.config/hypr/hyprland/scripts"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/rice/wallpaper"

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install swaybg matugen curl jq xdg-user-dirs findutils rofi
fi

link_tree "$MOD/home"

# First run: download the rotation list and theme everything from the first wallpaper, so the
# first login already has matching colors. Later runs leave your current wallpaper alone.
if [ "$DRY_RUN" = "1" ]; then
  skip "would download the wallpapers in wallpapers.txt and generate colors from the first one"
elif [ -s "$STATE" ] && [ -f "$(cat "$STATE")" ]; then
  skip "wallpaper already set ($(basename "$(cat "$STATE")"))"
elif ! have matugen || ! have curl || ! have jq; then
  warn "matugen/curl/jq missing — skipping the first wallpaper (rerun ./install.sh wallpaper)"
else
  info "downloading wallpapers from wallpapers.txt"
  "$SCRIPTS/wallpaper-rotate.sh" fetch || warn "could not download some wallpapers (offline?)"
  if "$SCRIPTS/wallpaper-set.sh" --restore && [ -s "$STATE" ]; then
    ok "colors generated from $(basename "$(cat "$STATE")")"
  else
    warn "no wallpaper yet — fallback colors stay until one is set (CTRL+SUPER+T)"
  fi
fi
