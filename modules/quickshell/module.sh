#!/usr/bin/env bash
# quickshell module: small overrides on top of end-4's illogical-impulse ("ii") shell.
# Only the bar files we changed are kept here; everything else comes from end-4.
#   bar layout: distro logo + workspaces | weather, ↓/↑ net | clock • AD date • Nepali (BS) date
#               | Samsung-style battery | CPU/RAM/swap | color picker, brightness, tray | indicators
#   clicking the clock opens hamropatro.com; services/NepaliDate.qml does the AD → BS conversion.
#   lock screen: sharp wallpaper + frosted-glass card (avatar from ~/.face, time, English + Nepali date).
#   wallpaper: no desktop clock.

MOD="${MODULE_DIR:-$RICE_DIR/modules/quickshell}"
II="$HOME/.config/quickshell/ii"
CONFIG="$HOME/.config/illogical-impulse/config.json"

# ── 1. base shell ────────────────────────────────────────────────────────────
# These files replace a handful of end-4's; without the rest of ii they do nothing.
if [ ! -d "$II" ]; then
  warn "$II not found — the base module installs it (Fedora/Arch); then rerun: ./install.sh quickshell"
  return 0 2>/dev/null || exit 0
fi

# ── 2. bar overrides ─────────────────────────────────────────────────────────
link_tree "$MOD/home"

# ── 3. settings (only the keys we care about; the rest of config.json is end-4's) ──
if [ ! -f "$CONFIG" ]; then
  warn "$CONFIG not found — start quickshell once, then rerun to apply bar settings"
elif ! have jq; then
  warn "jq not found — skipping bar settings in $CONFIG"
elif [ "$DRY_RUN" = "1" ]; then
  skip "would set bar options in $CONFIG"
else
  tmp="$(mktemp)"
  jq '.bar.topLeftIcon = "distro"
      | .bar.weather.enable = true
      | .bar.weather.city = "Kathmandu"
      | .bar.weather.enableGPS = false
      | .bar.utilButtons.showColorPicker = true
      | .bar.utilButtons.showKeyboardToggle = false
      | .bar.utilButtons.showScreenSnip = false
      | .background.widgets.clock.enable = false
      | .lock.blur.enable = false' "$CONFIG" >"$tmp" && mv "$tmp" "$CONFIG"
  ok "bar settings applied to $CONFIG"
fi

# ── 4. pick up the changes in a running session ──────────────────────────────
if [ "$DRY_RUN" != "1" ] && [ "${RICE_NO_RELOAD:-0}" != "1" ] && pgrep -x qs >/dev/null; then
  info "restarting quickshell"
  pkill -x qs || true
  setsid -f qs -c ii >/dev/null 2>&1 || warn "could not restart quickshell — log out and back in"
fi
