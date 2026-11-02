#!/usr/bin/env bash
# SUPER+SHIFT+S: select a region, copy it to the clipboard (as PNG, so it pastes as an image
# everywhere; it also lands in cliphist, SUPER+V) and save it to ~/Pictures/Screenshots.
# Clicking the notification opens it in swappy (arrows, text, blur);
# saving there writes a new file and copies the edited image.
pidof slurp >/dev/null && exit 0
geom=$(slurp) || exit 0
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png"
grim -g "$geom" "$file" || exit 1
wl-copy --type image/png <"$file"

# --action makes notify-send wait for a click, so don't hold up the keybind
(
    action=$(notify-send -a Screenshot -i "$file" --action=default=Edit \
        "Screenshot copied" "${file/#$HOME/\~}")
    [ "$action" = "default" ] && swappy -f "$file"
) >/dev/null 2>&1 &
