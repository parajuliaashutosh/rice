#!/usr/bin/env bash
# Battery for the lock screen's top-left corner (prints nothing on a desktop).
for bat in /sys/class/power_supply/BAT*; do
    [ -r "$bat/capacity" ] || continue
    cap=$(cat "$bat/capacity")
    status=$(cat "$bat/status" 2>/dev/null)
    icon="󰁹"
    [ "$status" = "Charging" ] && icon="󰂄"
    [ "$cap" -le 20 ] && [ "$status" != "Charging" ] && icon="󰂃"
    echo "$icon $cap%"
    exit 0
done
