#!/bin/sh
# Change volume by 2%, but at most once every 120 ms (stops touchpad jumps).
# Usage: volume-step.sh +   or   volume-step.sh -
lock="${XDG_RUNTIME_DIR:-/tmp}/waybar-volume-step"
now=$(date +%s%N)
last=$(cat "$lock" 2>/dev/null || echo 0)
[ $((now - last)) -lt 120000000 ] && exit 0
echo "$now" > "$lock"
wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "2%$1"
