-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List modes with: hyprctl monitors all

-- Main ultrawide: 5120x2160 at its 165 Hz mode, scale 1.
hl.monitor({
  output   = "DP-1",
  mode     = "5120x2160@165",
  position = "0x0",
  scale    = 1,
})

-- Anything else that gets plugged in: preferred mode, placed automatically.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Variable refresh rate: 0 = off, 1 = always, 2 = fullscreen only.
hl.config({ misc = { vrr = 2 } })
