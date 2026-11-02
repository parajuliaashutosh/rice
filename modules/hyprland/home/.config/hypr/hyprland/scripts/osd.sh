#!/usr/bin/env bash
# Volume/brightness keys: change the value, then show a mako progress bar that replaces itself.
#   osd.sh volume up|down     osd.sh brightness up|down
show() { # show <icon> <label> <percent>
    notify-send -a osd -t 1200 -h "int:value:$3" \
        -h string:x-canonical-private-synchronous:osd "$1  $2" "$3%"
}

case "$1 $2" in
    "volume up")   wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5 ;;
    "volume down") wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- ;;
    "brightness up")   brightnessctl -q s 5%+ ;;
    "brightness down") brightnessctl -q s 5%- ;;
    *) echo "usage: osd.sh volume|brightness up|down" >&2; exit 1 ;;
esac

case "$1" in
    volume)
        v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)  # "Volume: 0.45" or "Volume: 0.45 [MUTED]"
        pct=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$v")
        if [[ $v == *MUTED* ]]; then show "󰝟" "Volume (muted)" "$pct"; else show "󰕾" "Volume" "$pct"; fi
        ;;
    brightness)
        pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
        show "󰃠" "Brightness" "$pct"
        ;;
esac
