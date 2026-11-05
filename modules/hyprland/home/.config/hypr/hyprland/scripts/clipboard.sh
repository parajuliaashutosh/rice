#!/usr/bin/env bash

pkill -x fuzzel && exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/rice/clipboard"
mkdir -p "$cache"
conf="$HOME/.config/fuzzel/clipboard.ini"

img_re='^\[\[ binary data .+ (png|jpe?g|webp|bmp|gif) [0-9]+x[0-9]+ \]\]$'

menu() {
  local id text thumb
  while IFS=$'\t' read -r id text; do
    if [[ "$text" =~ $img_re ]]; then
      thumb="$cache/$id.png"
      if [ ! -s "$thumb" ]; then
        if command -v magick >/dev/null; then
          cliphist decode "$id" | magick - -thumbnail '256x256>' "$thumb" 2>/dev/null
        else
          cliphist decode "$id" >"$thumb"
        fi
      fi
      printf '%s\t \0icon\x1f%s\n' "$id" "$thumb"
    else
      printf '%s\t%s\n' "$id" "$text"
    fi
  done <<<"$list"
}

preview() {
  local file="$cache/full-$1" iw ih mw mh w h
  cliphist decode "$1" >"$file" || return
  read -r iw ih < <(magick identify -format '%w %h\n' "$file[0]" 2>/dev/null)
  read -r mw mh < <(hyprctl monitors -j | jq -r '.[] | select(.focused)
    | "\((.width / .scale) | floor) \((.height / .scale) | floor)"')
  read -r w h < <(awk -v iw="${iw:-800}" -v ih="${ih:-600}" -v mw="${mw:-1920}" -v mh="${mh:-1080}" 'BEGIN {
    s = (mw * 0.85) / iw; t = (mh * 0.85) / ih; if (t < s) s = t; if (s > 2) s = 2
    w = int(iw * s); h = int(ih * s); if (w < 240) w = 240; if (h < 120) h = 120
    print w, h }')
  if command -v imv >/dev/null; then
    imv -s shrink -W "$w" -H "$h" "$file"
  else
    kitty --class rice-clip-preview -o confirm_os_window_close=0 -o remember_window_size=no \
      -o initial_window_width="$((w + 20))" -o initial_window_height="$((h + 50))" \
      kitten icat --hold --scale-up --align center "$file"
  fi
  rm -f "$file"
}

list="$(cliphist list)" || exit 0
[ -n "$list" ] || { notify-send -a Clipboard "Clipboard is empty"; exit 0; }

index=0
while :; do
  id="$(menu | fuzzel --config "$conf" --dmenu --match-mode fzf --prompt 'Clipboard: ' \
    --with-nth 2 --accept-nth 1 --select-index "$index")"
  status=$?
  [ -n "$id" ] || break
  if [ "$status" -eq 10 ]; then
    index=$(($(cut -f1 <<<"$list" | grep -nx -- "$id" | cut -d: -f1) - 1))
    grep -q "^$id"$'\t''\[\[ binary data' <<<"$list" && preview "$id"
    continue
  fi
  [ "$status" -eq 0 ] && cliphist decode "$id" | wl-copy
  break
done

keep="$(cut -f1 <<<"$list")"
for f in "$cache"/*.png; do
  [ -e "$f" ] || continue
  grep -qx "$(basename "$f" .png)" <<<"$keep" || rm -f "$f"
done
