#!/usr/bin/env bash
# CTRL+SUPER+T: pick a wallpaper from ~/Pictures/Wallpapers (including the rotation folder).
walls="$HOME/Pictures/Wallpapers"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/rice/wallpapers"
[ -d "$walls" ] || { notify-send -a Wallpaper "No wallpapers" "Put images in ${walls/#$HOME/\~}"; exit 0; }
pkill -x rofi && exit 0
pkill -x fuzzel && exit 0
mkdir -p "$cache"

list=$(cd "$walls" && find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sed 's#^\./##' | sort)
[ -n "$list" ] || { notify-send -a Wallpaper "No wallpapers" "Put images in ${walls/#$HOME/\~}"; exit 0; }

thumb() {
  local t="$cache/$(printf '%s' "$1" | md5sum | cut -c1-16).png"
  if [ ! -s "$t" ] || [ "$walls/$1" -nt "$t" ]; then
    magick "$walls/$1[0]" -thumbnail '440x440>' "$t" 2>/dev/null || t="$walls/$1"
  fi
  printf '%s' "$t"
}

entries() {
  while IFS= read -r f; do
    printf "$1" "$f" "$(thumb "$f")"
  done <<<"$list"
}

color() {
  local v
  v=$(grep -m1 "^$1=" "$HOME/.config/fuzzel/colors.ini" 2>/dev/null | cut -d= -f2)
  printf '#%s' "${v:-$2}"
}

if command -v rofi >/dev/null; then
  n=$(wc -l <<<"$list")
  rows=$(((n + 3) / 4))
  [ "$rows" -gt 3 ] && rows=3
  theme="
* { bg: $(color background 151515ee); fg: $(color text e6e1e5ff); acc: $(color prompt 7aa2f7ff);
    sel: $(color selection 26272eff); bd: $(color border 7aa2f755);
    font: \"Noto Sans 12\"; background-color: transparent; text-color: @fg; }
window { width: 1040px; background-color: @bg; border: 1px; border-color: @bd; border-radius: 18px; padding: 18px; }
mainbox { spacing: 14px; children: [ inputbar, listview ]; }
inputbar { spacing: 8px; padding: 0 6px; children: [ prompt, entry ]; }
prompt { text-color: @acc; }
entry { placeholder: \"\"; cursor: text; }
listview { columns: 4; lines: $rows; spacing: 10px; fixed-height: true; fixed-columns: true; scrollbar: false; flow: horizontal; }
element { orientation: vertical; padding: 6px; border: 2px; border-color: transparent; border-radius: 14px; children: [ element-icon ]; }
element normal.normal, element alternate.normal { background-color: transparent; }
element selected.normal { background-color: @sel; border-color: @acc; }
element-icon { size: 230px; }
"
  choice=$(entries '%s\0icon\x1f%s\n' | rofi -dmenu -i -show-icons -p "Wallpaper" -theme-str "$theme") || exit 0
else
  choice=$(entries '%s\t \0icon\x1f%s\n' |
    fuzzel --dmenu --prompt "Wallpaper: " --width 30 --lines 4 --line-height 150 \
      --with-nth 2 --accept-nth 1) || exit 0
fi
[ -n "$choice" ] || exit 0
exec "$(dirname "$0")/wallpaper-set.sh" "$walls/$choice"
