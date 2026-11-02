#!/usr/bin/env bash
# SUPER+Tab: pick an open window from a fuzzel list and jump to it (replaces quickshell's overview).
set -euo pipefail

clients=$(hyprctl clients -j)
list=$(jq -r '
    [.[] | select(.mapped and .workspace.id != -1)]
    | sort_by(.focusHistoryID)
    | .[] | "\(.address)\t[\(.workspace.name)]  \(.class)  —  \(.title)"' <<<"$clients")
[ -n "$list" ] || { notify-send -a Hyprland "No open windows"; exit 0; }

# Show only the text after the tab; fuzzel's --index returns the picked line number
choice=$(cut -f2 <<<"$list" | fuzzel --dmenu --index --prompt "Window: " --width 70 --lines 12) || exit 0
address=$(sed -n "$((choice + 1))p" <<<"$list" | cut -f1)
[ -n "$address" ] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
