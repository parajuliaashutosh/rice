#!/usr/bin/env bash
# SUPER+P: Windows-style "Project" picker for the laptop screen + one external monitor.
set -euo pipefail

monitors=$(hyprctl monitors all -j)
internal=$(jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name // empty' <<<"$monitors")
external=$(jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)") | not)][0].name // empty' <<<"$monitors")

if [[ -z "$internal" || -z "$external" ]]; then
    notify-send -a Shell "Display" "No external monitor connected"
    exit 0
fi

choice=$(printf '%s\n' \
    "󰍹  PC screen only" \
    "󰍺  Duplicate" \
    "󰁔  Extend right" \
    "󰁍  Extend left" \
    "󰁝  Extend top" \
    "󰶐  Second screen only" |
    fuzzel --dmenu --prompt "Display: " --lines 6 --width 28) || exit 0

mon() { hyprctl eval "hl.monitor({ output = \"$1\", $2 })" >/dev/null; }
on='mode = "preferred", scale = "auto", disabled = false'

case "$choice" in
    *"PC screen only")     mon "$internal" "$on, position = \"0x0\""; mon "$external" 'disabled = true' ;;
    *"Duplicate")          mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto\", mirror = \"$internal\"" ;;
    *"Extend right")       mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-right\"" ;;
    *"Extend left")        mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-left\"" ;;
    *"Extend top")         mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-up\"" ;;
    *"Second screen only") mon "$external" "$on, position = \"0x0\""; mon "$internal" 'disabled = true' ;;
esac
