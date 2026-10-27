#!/usr/bin/env bash
# SUPER+P: Windows-style "Project" picker for the laptop screen + one external monitor.
set -euo pipefail

monitors=$(hyprctl monitors all -j)
internal=$(jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name // empty' <<<"$monitors")

# Hyprland keeps unplugged outputs around, and the NVIDIA driver leaves the
# connector "connected" with a stale EDID after unplug, falling back to VESA
# modes (<=1024x768). Only count it if the kernel offers a real mode.
external=""
for conn in /sys/class/drm/card*-*; do
    name=${conn##*/card[0-9]-}
    [[ $name =~ ^(eDP|LVDS|DSI|Writeback) ]] && continue
    [[ $(cat "$conn/status" 2>/dev/null) == connected ]] || continue
    awk -Fx '$1 > 1024 { found = 1 } END { exit !found }' "$conn/modes" 2>/dev/null || continue
    external=$name
    break
done

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
on='mode = "preferred", scale = 1, disabled = false'

case "$choice" in
    *"PC screen only")     mon "$internal" "$on, position = \"0x0\""; mon "$external" 'disabled = true' ;;
    *"Duplicate")          mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto\", mirror = \"$internal\"" ;;
    *"Extend right")       mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-right\"" ;;
    *"Extend left")        mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-left\"" ;;
    *"Extend top")         mon "$internal" "$on, position = \"0x0\""; mon "$external" "$on, position = \"auto-up\"" ;;
    *"Second screen only") mon "$external" "$on, position = \"0x0\""; mon "$internal" 'disabled = true' ;;
esac
