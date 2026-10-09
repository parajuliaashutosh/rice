#!/usr/bin/env bash
# Open a terminal as a kitty *tab* instead of a new tiled window.
# If a kitty window is on the current workspace, focus the most recently used
# one and add a tab to it; otherwise start a fresh kitty window.
# Needs allow_remote_control + listen_on in kitty.conf (see the kitty module).

new_window() { kitty -1 & exit; }

ws="$(hyprctl activeworkspace -j | jq -r '.id')"
target="$(hyprctl clients -j | jq -r --argjson ws "$ws" '
  [.[] | select(.class == "kitty" and .workspace.id == $ws)]
  | sort_by(.focusHistoryID) | first // empty
  | "\(.address) \(.pid)"')"
[ -n "$target" ] || new_window

read -r address pid <<<"$target"
sock="${XDG_RUNTIME_DIR}/kitty-${pid}"
[ -S "$sock" ] || new_window   # kitty started before remote control was enabled

# kitty adds the tab to its focused OS window, so make sure that's this one.
hyprctl dispatch "hl.dsp.focus({ window = \"address:${address}\" })" >/dev/null
for _ in $(seq 20); do
  kitten @ --to "unix:${sock}" ls 2>/dev/null \
    | jq -e '.[] | select(.is_focused)' >/dev/null && break
  sleep 0.025
done

kitten @ --to "unix:${sock}" launch --type=tab >/dev/null || new_window
