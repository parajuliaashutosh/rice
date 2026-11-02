local home_dir = os.getenv("HOME")

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Session (portals, screen sharing and apps that check the desktop name)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Applications (flatpak apps show up in fuzzel)
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)

-- Cursor (adwaita-cursor-theme, from Fedora's repo)
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Dark GTK apps without a settings daemon
hl.env("GTK_THEME", "Adwaita:dark")

-- KDE apps (Dolphin, Kate from the apps module): Breeze Dark colors and KDE file dialogs via the
-- KDE platform theme, only when it's installed (otherwise Qt would fail to load it)
for _, dir in ipairs({ "/usr/lib64/qt6/plugins", "/usr/lib/qt6/plugins" }) do
    if is_file_exists(dir .. "/platformthemes/KDEPlasmaPlatformTheme6.so") then
        hl.env("QT_QPA_PLATFORMTHEME", "kde")
        break
    end
end
