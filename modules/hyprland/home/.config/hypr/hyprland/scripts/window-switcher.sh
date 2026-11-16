#!/usr/bin/env bash
# SUPER+Tab / 3-finger swipe: pick an open window from a fuzzel list and jump to it.
# Each row shows the app's icon and name, the window title and its workspace. The previous
# window is preselected, so SUPER+Tab then Enter flips between the last two (like Alt+Tab).
set -euo pipefail

clients=$(hyprctl clients -j)
mapfile -t rows < <(jq -r '
    [.[] | select(.mapped and .workspace.id != -1)]
    | sort_by(.focusHistoryID)
    | .[] | [.address, .class, .workspace.name, .title] | @tsv' <<<"$clients")
[ ${#rows[@]} -gt 0 ] || { notify-send -a Hyprland "No open windows"; exit 0; }

app_dirs=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
    /var/lib/flatpak/exports/share/applications
    /usr/share/applications
)

# desktop_entry <class> — prints "<icon>\t<name>" from the app's .desktop file (matched by file
# name or StartupWMClass, ignoring case); prints nothing if no entry is found.
desktop_entry() {
    local class=$1 dir file=""
    [ -n "$class" ] || return 0
    for dir in "${app_dirs[@]}"; do
        [ -d "$dir" ] || continue
        file=$(find "$dir" -maxdepth 1 -iname "$class.desktop" -print -quit)
        [ -n "$file" ] || file=$(grep -lix "StartupWMClass=$class" "$dir"/*.desktop 2>/dev/null | head -1 || true)
        [ -n "$file" ] && break
    done
    [ -n "$file" ] || return 0
    awk -F= '/^\[/ { main = ($0 == "[Desktop Entry]") }
        main && $1 == "Icon" && icon == "" { icon = $2 }
        main && $1 == "Name" && name == "" { name = $2 }
        END { print icon "\t" name }' "$file"
}

# Rows for fuzzel: "<text>\0icon\x1f<icon>". Printed directly, since a bash variable can't hold \0.
declare -A icons names
print_rows() {
    local row class ws title key icon name text
    for row in "${rows[@]}"; do
        IFS=$'\t' read -r _ class ws title <<<"$row"
        key="_$class"
        if [ -z "${names[$key]+set}" ]; then
            icon="" name=""
            IFS=$'\t' read -r icon name < <(desktop_entry "$class"; echo) || true
            icons[$key]=${icon:-${class,,}}
            names[$key]=${name:-${class:-Window}}
        fi
        name=${names[$key]}
        [ ${#title} -gt 60 ] && title="${title:0:59}…"
        text="$name"
        [ -n "$title" ] && [ "$title" != "$name" ] && text+="   ·   $title"
        text+="   ·   󰍹   $ws"
        printf '%s\0icon\x1f%s\n' "$text" "${icons[$key]}"
    done
}

# Preselect the previously focused window (row 2) when there is one
select=0
[ ${#rows[@]} -gt 1 ] && select=1

choice=$(print_rows | fuzzel --dmenu --index \
    --prompt "  " --placeholder "Switch to window…" \
    --width 72 --lines 10 --minimal-lines --line-height 34 \
    --selection-radius 10 --select-index "$select") || exit 0

address=$(cut -f1 <<<"${rows[$choice]}")
[ -n "$address" ] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
