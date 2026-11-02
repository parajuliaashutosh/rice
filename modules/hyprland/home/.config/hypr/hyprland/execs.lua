-- put former exec-once commands inside the func and former exec commands outside
local scripts = "$HOME/.config/hypr/hyprland/scripts"

hl.on("hyprland.start", function ()
    -- Session environment for systemd/dbus-activated services (portals, polkit, pipewire)
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    -- Bar, notifications, wallpaper (and its colors)
    hl.exec_cmd(scripts .. "/wallpaper-set.sh --restore")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")

    -- Tray: wifi, bluetooth
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Lock / idle
    hl.exec_cmd("hypridle")

    -- Clipboard history (SUPER+V)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Adwaita 24")
end)
