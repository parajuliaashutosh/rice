#!/usr/bin/env bash
# Sets the wallpaper (swaybg) and re-themes bar, launcher, notifications, borders and lock screen
# from it (matugen). Replaces quickshell's switchwall.sh.
#   wallpaper-set.sh <image>        use this image
#   wallpaper-set.sh --restore      the last one again (Hyprland start)
#   wallpaper-set.sh --random       a random image from ~/Pictures/Wallpapers
#   wallpaper-set.sh --toggle-mode  switch the colors between dark and light
# Outside a Wayland session (e.g. during install) only the colors are generated.

state="${XDG_STATE_HOME:-$HOME/.local/state}/rice"
walls="$HOME/Pictures/Wallpapers"
mkdir -p "$state"
mode=$(cat "$state/mode" 2>/dev/null || echo dark)

case "${1:-}" in
    --restore) img=$(cat "$state/wallpaper" 2>/dev/null) ;;
    --random) img=$(find "$walls" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1) ;;
    --toggle-mode)
        [ "$mode" = dark ] && mode=light || mode=dark
        echo "$mode" >"$state/mode"
        img=$(cat "$state/wallpaper" 2>/dev/null)
        ;;
    -*|"") sed -n '2,9p' "$0"; exit 1 ;;
    *) img=$(realpath "$1") ;;
esac

if [ -z "$img" ] || [ ! -f "$img" ]; then
    # nothing set yet (or the file is gone): first wallpaper of the rotation, else a plain color
    img=$(find "$walls" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1)
fi

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # start the new swaybg before killing the old one, so there's no flash of black
    old=$(pgrep -x swaybg)
    if [ -n "$img" ]; then setsid -f swaybg -m fill -i "$img" >/dev/null 2>&1
    else setsid -f swaybg -c '#151515' >/dev/null 2>&1; fi
    [ -n "$old" ] && (sleep 0.5; kill $old 2>/dev/null) &
fi

[ -n "$img" ] || exit 0
echo "$img" >"$state/wallpaper"

# matugen 4 asks which color to use unless told; matugen 3 (Fedora's) picks the most dominant
# one on its own and doesn't know the flag
pick=()
matugen image --help 2>/dev/null | grep -q -- '--source-color-index' && pick=(--source-color-index 0)
matugen image "$img" -m "$mode" "${pick[@]}" -q || notify-send -a Wallpaper "matugen failed" "Colors not updated"
