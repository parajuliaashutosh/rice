#!/usr/bin/env bash
# Screen recording with wf-recorder. Run again to stop.
#   record.sh                    region, no sound
#   record.sh --fullscreen       focused monitor
#   record.sh --fullscreen --sound   focused monitor + desktop audio
if pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder
    notify-send -a Recorder "Recording stopped" "Saved to $(xdg-user-dir VIDEOS 2>/dev/null || echo ~/Videos)/Recordings"
    exit 0
fi

dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Recordings"
mkdir -p "$dir"
file="$dir/Recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
args=(-f "$file")

if [[ " $* " == *" --fullscreen "* ]]; then
    args+=(-o "$(hyprctl activeworkspace -j | jq -r '.monitor')")
else
    geom=$(slurp) || exit 0
    args+=(-g "$geom")
fi
if [[ " $* " == *" --sound "* ]]; then
    # desktop audio = the default output's monitor source
    sink=$(pactl get-default-sink 2>/dev/null)
    if [ -n "$sink" ]; then args+=("--audio=$sink.monitor"); else args+=(--audio); fi
fi

notify-send -a Recorder "Recording started" "Press the same keys again to stop"
exec wf-recorder "${args[@]}" >/dev/null 2>&1
