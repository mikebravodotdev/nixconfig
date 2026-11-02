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
      drag_3fg             = 1,  -- three-finger drag (macOS-style)
    },
  },

  misc = {
    key_press_enables_dpms   = true,
    mouse_move_enables_dpms  = true,
  },
})

-- Touchpad gestures. 3 fingers is reserved for drag (drag_3fg above), so
-- workspace switching lives on 4 fingers.
hl.gesture({ fingers = 4, direction = "left",  action = function() hl.dispatch(hl.dsp.focus({ workspace = "r-1" })) end })
hl.gesture({ fingers = 4, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r+1" })) end })
hl.gesture({ fingers = 4, direction = "down",  action = "fullscreen" })

-- Magic Trackpad: max pointer speed (range -1.0..1.0), scoped so mice are unaffected.
hl.device({ name = "apple-inc.-magic-trackpad-2", sensitivity = 1.0 })
