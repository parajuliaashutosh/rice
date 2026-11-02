-- Default variables
-- Copy these to ~/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- Apps
-- kitty opens as a tab in the workspace's existing kitty; terminalWindow forces a separate window
local first = "~/.config/hypr/hyprland/scripts/launch_first_available.sh"
terminal = "~/.config/hypr/hyprland/scripts/kitty_tab.sh"
terminalWindow = first .. " 'kitty -1' 'foot' 'alacritty' 'wezterm' 'xterm'"
fileManager = first .. " 'dolphin' 'thunar' 'nautilus' 'nemo' 'kitty -1 yazi' 'kitty -1 mc'"
browser = first .. " 'brave-browser' 'google-chrome-stable' 'firefox' 'brave' 'chromium' 'librewolf'"
codeEditor = first .. " 'code' 'codium' 'cursor' 'zed' 'zeditor' 'command -v nvim && kitty -1 nvim'"
officeSoftware = first .. " 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = first .. " 'kate' 'gnome-text-editor' 'command -v nvim && kitty -1 nvim' 'kitty -1 nano'"
volumeMixer = first .. " 'pavucontrol'"
settingsApp = first .. " 'nm-connection-editor'"
taskManager = first .. " 'kitty -1 btop' 'kitty -1 top'"

workspaceGroupSize = 10
