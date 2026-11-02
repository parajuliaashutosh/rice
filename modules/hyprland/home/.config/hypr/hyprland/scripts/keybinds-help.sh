#!/usr/bin/env bash
# SUPER+/: searchable list of every keybind that has a description (from hyprctl binds).
set -euo pipefail

hyprctl binds -j | jq -r '
    def mods: [ (if . % 128 >= 64 then "SUPER" else empty end),
                (if . % 8 >= 4 then "CTRL" else empty end),
                (if . % 16 >= 8 then "ALT" else empty end),
                (if . % 2 >= 1 then "SHIFT" else empty end) ];
    .[] | select(.description != "")
    | "\((.modmask | mods) + [.key] | join(" + "))\t\(.description)"' |
    column -t -s $'\t' |
    fuzzel --dmenu --prompt "Keybinds: " --width 80 --lines 20 >/dev/null || true
