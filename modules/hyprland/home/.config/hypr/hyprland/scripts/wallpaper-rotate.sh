#!/usr/bin/env bash
# Wallpaper rotation from the list in ~/.config/hypr/wallpapers.txt (wallhaven links or ids).
# Changes only when the screen locks (hypridle's lock_cmd: Super+L, idle, suspend), so the
# wallpaper and the colors re-themed from it never shift while you're using the machine.
#   wallpaper-rotate.sh fetch   download whatever on the list isn't here yet
#   wallpaper-rotate.sh next    fetch, then switch to the next wallpaper on the list

list="$HOME/.config/hypr/wallpapers.txt"
dir="$HOME/Pictures/Wallpapers/rotation"
shell_config="$HOME/.config/illogical-impulse/config.json"
switchwall="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ids() { grep -v '^\s*#' "$list" 2>/dev/null | grep -oE '[a-z0-9]{6}\s*$' | tr -d ' \t'; }

fetch() {
    mkdir -p "$dir"
    for id in $(ids); do
        ls "$dir/wallhaven-$id".* >/dev/null 2>&1 && continue
        url=$(curl -fsS --max-time 15 "https://wallhaven.cc/api/v1/w/$id" | jq -r '.data.path // empty')
        [ -n "$url" ] || { echo "$id: not found on wallhaven" >&2; continue; }
        curl -fsS --max-time 120 -o "$dir/${url##*/}.part" "$url" &&
            mv "$dir/${url##*/}.part" "$dir/${url##*/}" && echo "downloaded $id"
    done
}

next() {
    # Locking again while locked (idle lock, then the suspend's lock) shouldn't skip one
    stamp="$runtime/wallpaper-rotate.last"
    [ $(($(date +%s) - $(stat -c %Y "$stamp" 2>/dev/null || echo 0))) -lt 60 ] && return
    touch "$stamp"

    fetch
    files=()
    for id in $(ids); do
        f=$(ls "$dir/wallhaven-$id".* 2>/dev/null | head -n1)
        [ -n "$f" ] && files+=("$f")
    done
    [ ${#files[@]} -gt 0 ] || return

    # The one after the current wallpaper, in list order (the first if it isn't on the list)
    current=$(jq -r '.background.wallpaperPath' "$shell_config" 2>/dev/null)
    pick="${files[0]}"
    for i in "${!files[@]}"; do
        [ "${files[$i]}" = "$current" ] && pick="${files[$(((i + 1) % ${#files[@]}))]}"
    done
    [ "$pick" = "$current" ] && return
    "$switchwall" --image "$pick"
}

exec 9>"$runtime/wallpaper-rotate.lock"
flock -n 9 || exit 0
case "$1" in
    fetch) fetch ;;
    next) next ;;
    *) sed -n '2,6p' "$0"; exit 1 ;;
esac
