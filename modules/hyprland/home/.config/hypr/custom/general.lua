

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

-- Window close (Super+Q): "TV switching off". gnomed squashes the window vertically
-- into a thin line through its centre; the accelerating curve makes it snap shut at the end,
-- and the fade holds full opacity until late so the collapsing line stays visible.
hl.curve("tvOff", {
    type = "bezier",
    points = {{0.7, 0}, {0.84, 0}}
})
hl.curve("tvOffFade", {
    type = "bezier",
    points = {{0.9, 0}, {1, 0.3}}
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "tvOff",
    style = "gnomed"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3,
    bezier = "tvOffFade"
})
