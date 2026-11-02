-- Window rules, after Omarchy 4.x. https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local function rule(match, rules)
  if type(match) == "string" then match = { class = match } end
  rules.match = match
  hl.window_rule(rules)
end

-- Ignore maximize requests from apps.
rule({ class = ".*" }, { suppress_event = "maximize" })

-- Fix some dragging issues with XWayland.
rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
     { no_focus = true })

-- Tag terminals and browsers so other rules and binds can target them.
rule("(Alacritty|kitty|foot|org\\.codeberg\\.dnkl\\.foot|com\\.mitchellh\\.ghostty|wezterm)", { tag = "+terminal" })
rule("((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)", { tag = "+chromium-based-browser" })
rule("([fF]irefox|zen|librewolf)", { tag = "+firefox-based-browser" })
rule({ tag = "chromium-based-browser" }, { tile = true })

-- Floating utilities: centered, 875x600.
rule({ tag = "floating-window" }, { float = true, center = true, size = { 875, 600 } })
rule("(org.gnome.NautilusPreviewer|org.gnome.Evince|About|imv|mpv|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)",
     { tag = "+floating-window" })

-- File pickers and permission prompts from the portal always float.
rule("xdg-desktop-portal-gtk", { tag = "+floating-window" })
rule({ class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)",
       title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)" },
     { tag = "+floating-window" })

-- Picture-in-picture: small, pinned, top right.
rule({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
rule({ tag = "pip" }, {
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Google Meet's PiP uses the meeting title instead.
rule({ tag = "chromium-based-browser", title = "^Meet - .+" }, {
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
})

-- Hide the "is sharing your screen" indicator windows.
rule({ title = ".*is sharing.*" }, { workspace = "special silent" })

-- Terminals get light transparency; the "transparent" tag opts other windows in.
rule({ tag = "terminal" },    { opacity = "0.985 0.96" })
rule({ tag = "transparent" }, { opacity = "0.985 0.96" })

-- Keep the screen awake while a window is tagged noidle.
rule({ tag = "noidle" }, { idle_inhibit = "always" })

-- Shell overlays should pop in without compositor animation.
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^(qs-launcher|qs-clipboard|qs-system-menu|qs-appearance|qs-wallpaper|qs-osd|qs-notifications|qs-bar)$" }, no_anim = true })

-- xwaylandvideobridge (screen-share bridge for XWayland apps) maps a real window
-- on login. Keep it alive but invisible, tiny, unfocusable, and off-screen.
rule({ class = "^xwaylandvideobridge$" }, {
  float = true,
  size = { 1, 1 },
  move = { "(monitor_w*2)", "(monitor_h*2)" },
  opacity = "0.0 override 0.0 override",
  no_anim = true,
  no_blur = true,
  no_focus = true,
  no_initial_focus = true,
})
