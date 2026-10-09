

-- Vertical workspace switch animation (overrides hyprland/general.lua)
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slidefadevert 20%"
})
