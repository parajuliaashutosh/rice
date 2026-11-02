# Sourced from ~/.bash_profile and ~/.zprofile (session module): logging in on tty1 starts
# Hyprland. Other ttys (Ctrl+Alt+F2…) stay plain shells, handy for fixing a broken config.
# To turn it off: touch ~/.config/rice/no-autostart   (rm it to turn it back on)
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] && [ "${XDG_VTNR:-}" = "1" ] &&
    [ ! -e "$HOME/.config/rice/no-autostart" ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    elif command -v Hyprland >/dev/null 2>&1; then
        exec Hyprland
    fi
fi
