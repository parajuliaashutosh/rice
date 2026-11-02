#!/usr/bin/env bash
# kitty module: the kitty terminal, its config (tabs, Tokyo Night colors) and the
# search/scroll kittens. Colors are fixed (not from the wallpaper).

MOD="${MODULE_DIR:-$RICE_DIR/modules/kitty}"

# ── 1. kitty itself ──────────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install kitty
fi

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"
