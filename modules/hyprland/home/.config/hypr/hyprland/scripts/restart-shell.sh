#!/usr/bin/env bash
# SUPER+Escape / CTRL+SUPER+R: close anything grabbing the screen, restart bar + notifications.
pkill -x fuzzel
pkill -x slurp
pkill -x waybar
pkill -x mako
sleep 0.3
setsid -f waybar >/dev/null 2>&1
setsid -f mako >/dev/null 2>&1
