#!/usr/bin/env bash
# CTRL+ALT+Del: lock / log out / suspend / reboot / shut down.
choice=$(printf '%s\n' \
    "󰌾  Lock" \
    "󰍃  Log out" \
    "󰤄  Suspend" \
    "󰜉  Reboot" \
    "󰐥  Shut down" |
    fuzzel --dmenu --prompt "Session: " --lines 5 --width 22) || exit 0

case "$choice" in
    *Lock)       loginctl lock-session ;;
    *"Log out")  command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' ;;
    *Suspend)    systemctl suspend || loginctl suspend ;;
    *Reboot)     systemctl reboot || loginctl reboot ;;
    *"Shut down") systemctl poweroff || loginctl poweroff ;;
esac
