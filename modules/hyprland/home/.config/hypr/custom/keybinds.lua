hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Browser: open Brave's Personal profile ("Default") directly instead of the profile picker
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd("brave-browser --profile-directory=Default"), { description = "App: Browser" })
