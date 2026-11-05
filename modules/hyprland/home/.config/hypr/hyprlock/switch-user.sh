#!/usr/bin/env bash
if busctl --system status org.freedesktop.DisplayManager >/dev/null 2>&1; then
  exec busctl --system call org.freedesktop.DisplayManager \
    "${XDG_SEAT_PATH:-/org/freedesktop/DisplayManager/Seat0}" \
    org.freedesktop.DisplayManager.Seat SwitchToGreeter
fi
vt=2
[ "${XDG_VTNR:-1}" = 2 ] && vt=3
exec busctl --system call org.freedesktop.login1 /org/freedesktop/login1/seat/seat0 \
  org.freedesktop.login1.Seat SwitchTo u "$vt"
