#!/usr/bin/env bash
# Prints a warning on the lock screen while Caps Lock is on.
if hyprctl devices -j 2>/dev/null | jq -e '[.keyboards[] | select(.main) | .capsLock] | any' >/dev/null; then
    echo "Caps Lock is on"
fi
