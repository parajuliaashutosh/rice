#!/usr/bin/env bash
# Weather for waybar from wttr.in (no API key). Cached for 30 min so a bar restart doesn't refetch;
# an old cached value is shown while offline. City: RICE_WEATHER_CITY (default Kathmandu).
city="${RICE_WEATHER_CITY:-Kathmandu}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/rice/weather-${city// /_}.json"
mkdir -p "${cache%/*}"

if [ -z "$(find "$cache" -mmin -30 2>/dev/null)" ]; then
    # %c condition icon, %t temperature, %C condition text, %f feels like, %h humidity, %w wind
    if raw=$(curl -fsS --max-time 10 "https://wttr.in/${city// /+}?format=%c|%t|%C|%f|%h|%w&m" 2>/dev/null) &&
        [ "$(tr -cd '|' <<<"$raw" | wc -c)" -eq 5 ]; then
        IFS='|' read -r icon temp cond feels hum wind <<<"$raw"
        jq -cn --arg t "$(echo "$icon" | xargs) ${temp#+}" \
            --arg tip "$city: $cond, feels ${feels#+}, humidity $hum, wind $wind" \
            '{text: $t, tooltip: $tip}' >"$cache.tmp" && mv "$cache.tmp" "$cache"
    fi
fi

if [ -s "$cache" ]; then cat "$cache"; else echo '{"text": "", "tooltip": "weather unavailable"}'; fi
