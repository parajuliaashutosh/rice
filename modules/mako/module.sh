#!/usr/bin/env bash
# mako module: notifications (replaces quickshell's). SUPER+N shows the last one again,
# CTRL+SUPER+N dismisses all; volume/brightness keys show a progress bar through it (osd.sh).
# The config is written by matugen from the wallpaper (wallpaper module), so it's a real file:
# a fallback copy is installed only when none exists.

MOD="${MODULE_DIR:-$RICE_DIR/modules/mako}"

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install mako libnotify
fi

dst="$HOME/.config/mako/config"
if [ -e "$dst" ] && [ ! -L "$dst" ]; then
  skip "~/.config/mako/config present"
else
  [ -L "$dst" ] && run rm "$dst"
  run mkdir -p "$(dirname "$dst")"
  run cp "$MOD/fallback/config" "$dst" && ok "~/.config/mako/config (fallback until the first wallpaper)"
fi

if [ "$DRY_RUN" != "1" ] && [ "${RICE_NO_RELOAD:-0}" != "1" ] && pgrep -x mako >/dev/null; then
  makoctl reload && ok "reloaded mako"
fi
