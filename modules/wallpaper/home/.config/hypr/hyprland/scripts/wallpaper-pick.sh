#!/usr/bin/env bash
# CTRL+SUPER+T: pick a wallpaper from ~/Pictures/Wallpapers (including the rotation folder).
walls="$HOME/Pictures/Wallpapers"
[ -d "$walls" ] || { notify-send -a Wallpaper "No wallpapers" "Put images in ${walls/#$HOME/\~}"; exit 0; }

list=$(cd "$walls" && find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sed 's#^\./##' | sort)
[ -n "$list" ] || { notify-send -a Wallpaper "No wallpapers" "Put images in ${walls/#$HOME/\~}"; exit 0; }

choice=$(fuzzel --dmenu --prompt "Wallpaper: " --width 60 <<<"$list") || exit 0
exec "$(dirname "$0")/wallpaper-set.sh" "$walls/$choice"
