-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout  = "us",
    kb_variant = "",
    kb_model   = "",
    kb_options = "",
    kb_rules   = "",

    follow_mouse = 1,
    sensitivity  = 0,

    repeat_rate  = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll       = false,
      clickfinger_behavior = true,
      scroll_factor        = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms   = true,
    mouse_move_enables_dpms  = true,
  },
})

-- Touchpad gestures (harmless on a desktop, useful if you add a laptop).
hl.gesture({ fingers = 3, direction = "left",  action = function() hl.dispatch(hl.dsp.focus({ workspace = "r-1" })) end })
hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r+1" })) end })
hl.gesture({ fingers = 4, direction = "left",  action = function() hl.dispatch(hl.dsp.window.move({ workspace = "r-1" })) end })
hl.gesture({ fingers = 4, direction = "right", action = function() hl.dispatch(hl.dsp.window.move({ workspace = "r+1" })) end })
hl.gesture({ fingers = 4, direction = "down",  action = "fullscreen" })
