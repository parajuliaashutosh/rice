#!/usr/bin/env bash
# Way out when the shell (quickshell: launcher, Super+V clipboard, bar) freezes with its
# overlay covering the screen. Same idea as upstream's Ctrl+Super+R / "kill it from a TTY",
# plus a liveness check so a hang (not just a crash) is caught.
#   qs-rescue.sh         Super+Escape, or `unstick` from a TTY (Ctrl+Alt+F3):
#                        closes every shell overlay; if quickshell doesn't answer, or it's
#                        pressed again within 5s, kills and restarts it
#   qs-rescue.sh watch   restarts a frozen or crashed quickshell on its own (execs.lua)

cfg="${qsConfig:-ii}"

# From a TTY, borrow the running Hyprland session's environment
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    sig=$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -n1)
    [ -n "$sig" ] && export HYPRLAND_INSTANCE_SIGNATURE="$sig"
fi
if [ -z "$WAYLAND_DISPLAY" ]; then
    sock=$(ls "$XDG_RUNTIME_DIR" 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -n1)
    [ -n "$sock" ] && export WAYLAND_DISPLAY="$sock"
fi

# Answers only if quickshell's main thread is free (a stuck overlay means it isn't).
# panelFamily is registered by shell.qml itself, so it's there whatever is (un)loaded or
# reloading; a handler inside a panel vanishes during hot reloads and family switches.
alive() { timeout 5 qs -c "$cfg" ipc show 2>/dev/null | grep -q '^target panelFamily$'; }

# quickshell is the notification daemon too, so notify once the new one is up
notify_later() { (sleep "$1"; notify-send -a Shell "$2" "$3") >/dev/null 2>&1 9>&- & }

restart() {
    pkill -9 -x qs
    pkill -9 -x quickshell
    sleep 0.3
    setsid -f qs -c "$cfg" >/dev/null 2>&1 9>&- # 9: the watch lock, not for the shell to keep
}

if [ "$1" = "watch" ]; then
    exec 9>"$XDG_RUNTIME_DIR/qs-rescue.lock"
    flock -w 5 9 || exit 0 # already watching (5s: a replaced watcher's last sleep still holds it)
    fails=0
    last=$(date +%s)
    while sleep 5; do
        now=$(date +%s)
        # Long gap = just woke from suspend: the shell gets a fresh start too
        if [ $((now - last)) -gt 20 ]; then last=$now; fails=0; continue; fi
        last=$now
        pid=$(pgrep -xof "qs -c $cfg")
        # Starting up takes ~10s before it answers: leave a young shell alone
        if [ -n "$pid" ] && [ "$(ps -o etimes= -p "$pid")" -lt 30 ]; then fails=0; continue; fi
        # Not running (crashed) counts too, so a crash also comes back
        if [ -n "$pid" ] && alive; then fails=0; else fails=$((fails + 1)); fi
        # ~30-60s without an answer: a busy moment (reload, monitor hotplug) never lasts that long
        if [ "$fails" -ge 6 ]; then
            restart
            notify_later 12 "Shell restarted" "It had stopped responding"
            fails=0
        fi
    done
fi

hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1 # keybinds back on, if a submap ate them
stamp="$XDG_RUNTIME_DIR/qs-rescue.pressed"
pressed=$(stat -c %Y "$stamp" 2>/dev/null || echo 0)
if alive && [ $(($(date +%s) - pressed)) -gt 5 ]; then
    for t in search session sidebarLeft sidebarRight cheatsheet mediaControls osk; do
        timeout 2 qs -c "$cfg" ipc call "$t" close >/dev/null 2>&1
    done
    touch "$stamp"
    notify-send -a Shell "Overlays closed" "Still stuck? Press Super+Esc again to restart the shell"
    echo "overlays closed (run again within 5s to restart the shell)"
else
    rm -f "$stamp"
    restart
    notify_later 12 "Shell restarted" ""
    echo "shell restarted"
fi
