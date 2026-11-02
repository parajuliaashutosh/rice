#!/usr/bin/env bash
# fuzzel module: app launcher (tap SUPER) and the menus the keybinds open: clipboard history
# (SUPER+V, via cliphist), emoji (SUPER+.), window switcher (SUPER+Tab), session (CTRL+ALT+Del),
# keybind cheatsheet (SUPER+/), wallpapers (CTRL+SUPER+T).
# Colors: colors.ini is written by matugen (wallpaper module); a fallback copy is installed first.

MOD="${MODULE_DIR:-$RICE_DIR/modules/fuzzel}"

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install fuzzel cliphist wl-clipboard adwaita-icon-theme
fi

link_tree "$MOD/home"

dst="$HOME/.config/fuzzel/colors.ini"
if [ -e "$dst" ] && [ ! -L "$dst" ]; then
  skip "~/.config/fuzzel/colors.ini present"
else
  [ -L "$dst" ] && run rm "$dst"
  run cp "$MOD/fallback/colors.ini" "$dst" && ok "~/.config/fuzzel/colors.ini (fallback until the first wallpaper)"
fi
