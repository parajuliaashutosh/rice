

-- Vertical workspace switch animation (overrides hyprland/general.lua).
-- Plain slide like end-4's default: a crossfade lingers visibly through the curve's long tail
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slidevert"
})

-- Layer fade-in long enough to see (was 50ms, which read as a pop; 150ms now); the launcher uses it
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 1.5,
    bezier = "menu_decel"
})
