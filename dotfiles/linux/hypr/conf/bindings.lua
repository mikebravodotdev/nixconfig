-- Keybindings, after Omarchy 4.x, written as plain hl.bind calls.
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local function bind(keys, description, action, opts)
  opts = opts or {}
  opts.description = description
  if type(action) == "string" then action = hl.dsp.exec_cmd(action) end
  hl.bind(keys, action, opts)
end

local exec = hl.dsp.exec_cmd

---------------------------------------------------------------
-- Apps
---------------------------------------------------------------
bind("SUPER + RETURN",         "Terminal",     programs.terminal)
bind("SUPER + SHIFT + RETURN", "Browser",      programs.browser)
bind("SUPER + SHIFT + B",      "Browser",      programs.browser)
bind("SUPER + SHIFT + ALT + B","Browser (private)", programs.browser .. " --incognito")
bind("SUPER + SHIFT + F",      "File manager", programs.fileManager)
bind("SUPER + SPACE",          "Launcher",     "quickshell ipc call launcher toggle")

---------------------------------------------------------------
-- Windows
---------------------------------------------------------------
bind("SUPER + W", "Close window", hl.dsp.window.close())
bind("SUPER + Q", "Close window", hl.dsp.window.close())
bind("SUPER + J", "Toggle split", hl.dsp.layout("togglesplit"))
bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + ALT + F", "Full width (maximize)", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Focus and swap with arrows.
bind("SUPER + LEFT",  "Focus left",  hl.dsp.focus({ direction = "l" }))
bind("SUPER + RIGHT", "Focus right", hl.dsp.focus({ direction = "r" }))
bind("SUPER + UP",    "Focus up",    hl.dsp.focus({ direction = "u" }))
bind("SUPER + DOWN",  "Focus down",  hl.dsp.focus({ direction = "d" }))

bind("SUPER + SHIFT + LEFT",  "Swap left",  hl.dsp.window.swap({ direction = "l" }))
bind("SUPER + SHIFT + RIGHT", "Swap right", hl.dsp.window.swap({ direction = "r" }))
bind("SUPER + SHIFT + UP",    "Swap up",    hl.dsp.window.swap({ direction = "u" }))
bind("SUPER + SHIFT + DOWN",  "Swap down",  hl.dsp.window.swap({ direction = "d" }))

-- Cycle windows.
bind("ALT + TAB",         "Next window",     hl.dsp.window.cycle_next())
bind("ALT + SHIFT + TAB", "Previous window", hl.dsp.window.cycle_next({ next = false }))

-- Resize with SUPER + minus / equal (keycodes 20 / 21).
bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0,   relative = true }), { repeating = true })
bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100,  y = 0,   relative = true }), { repeating = true })
bind("SUPER + SHIFT + code:20", "Shrink window up",   hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100,  relative = true }), { repeating = true })

-- Mouse: move and resize.
bind("SUPER + mouse:272", "Move window",   hl.dsp.window.drag(),   { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

---------------------------------------------------------------
-- Workspaces (SUPER + 1..0 are keycodes 10..19)
---------------------------------------------------------------
for ws = 1, 10 do
  local key = "code:" .. tostring(ws + 9)
  bind("SUPER + " .. key,                 "Workspace " .. ws,                 hl.dsp.focus({ workspace = ws }))
  bind("SUPER + SHIFT + " .. key,         "Move window to workspace " .. ws,  hl.dsp.window.move({ workspace = ws }))
  bind("SUPER + SHIFT + ALT + " .. key,   "Move window silently to " .. ws,   hl.dsp.window.move({ workspace = ws, follow = false }))
end

bind("SUPER + TAB",        "Next workspace",     hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + SHIFT + TAB","Previous workspace", hl.dsp.focus({ workspace = "m-1" }))
bind("SUPER + CTRL + TAB", "Former workspace",   hl.dsp.focus({ workspace = "previous" }))
bind("SUPER + mouse_down", "Next workspace",     hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + mouse_up",   "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))

-- Scratchpad and Quake-style terminal.
bind("SUPER + S",         "Toggle scratchpad",       hl.dsp.workspace.toggle_special("scratchpad"))
bind("SUPER + ALT + S",   "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
bind("SUPER + grave",     "Toggle Quake console",    hl.dsp.workspace.toggle_special("qconsole"))
bind("SUPER + SHIFT + grave", "Move window to Quake console", hl.dsp.window.move({ workspace = "special:qconsole", follow = false }))

-- Multi-monitor.
bind("CTRL + ALT + TAB",            "Focus next monitor",     hl.dsp.focus({ monitor = "+1" }))
bind("SUPER + SHIFT + ALT + LEFT",  "Workspace to left monitor",  hl.dsp.workspace.move({ monitor = "l" }))
bind("SUPER + SHIFT + ALT + RIGHT", "Workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))

-- Groups (tabbed windows).
bind("SUPER + G",              "Toggle group",           hl.dsp.group.toggle())
bind("SUPER + ALT + G",        "Move window out of group", hl.dsp.window.move({ out_of_group = true }))
bind("SUPER + ALT + LEFT",     "Move window into group left",  hl.dsp.window.move({ into_group = "l" }))
bind("SUPER + ALT + RIGHT",    "Move window into group right", hl.dsp.window.move({ into_group = "r" }))
bind("SUPER + ALT + UP",       "Move window into group up",    hl.dsp.window.move({ into_group = "u" }))
bind("SUPER + ALT + DOWN",     "Move window into group down",  hl.dsp.window.move({ into_group = "d" }))
bind("SUPER + ALT + TAB",      "Next window in group",   hl.dsp.group.next())
bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())
bind("SUPER + CTRL + LEFT",    "Group focus left",       hl.dsp.group.prev())
bind("SUPER + CTRL + RIGHT",   "Group focus right",      hl.dsp.group.next())

---------------------------------------------------------------
-- Universal copy / paste / cut (Omarchy's Super+C/V/X)
-- Sends Ctrl+C/V/X to apps and Ctrl+Shift+C/V to terminals.
---------------------------------------------------------------
local function send_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_is_terminal()
  local w = hl.get_active_window()
  if not w then return false end
  for _, tag in ipairs(w.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

local function universal(app_mods, app_key, term_mods, term_key)
  return function()
    if active_is_terminal() then send_once(term_mods, term_key)() else send_once(app_mods, app_key)() end
  end
end

bind("SUPER + A", "Select all", send_once("CTRL", "A"))
bind("SUPER + C", "Universal copy",  universal("CTRL", "C", "CTRL SHIFT", "C"))
bind("SUPER + V", "Universal paste", universal("CTRL", "V", "CTRL SHIFT", "V"))
bind("SUPER + X", "Universal cut",   send_once("CTRL", "X"))

-- Clipboard history panel (Quickshell + cliphist).
bind("SUPER + CTRL + V", "Clipboard history", "quickshell ipc call clipboard toggle")

---------------------------------------------------------------
-- Shell (Quickshell IPC): notifications and bar
---------------------------------------------------------------
bind("SUPER + comma",         "Dismiss last notification", "quickshell ipc call notifications dismissOne")
bind("SUPER + SHIFT + comma", "Dismiss all notifications", "quickshell ipc call notifications dismissAll")
bind("SUPER + SHIFT + SPACE", "Toggle top bar",            "quickshell ipc call bar toggle")
bind("SUPER + SHIFT + ALT + comma", "Notification history", "quickshell ipc call panels toggle notifications")
bind("SUPER + CTRL + ALT + comma",  "Do not disturb",       "quickshell ipc call notifications toggleDnd")

---------------------------------------------------------------
-- Appearance: theme and wallpaper switcher
---------------------------------------------------------------
bind("SUPER + CTRL + T",     "Theme switcher",      "quickshell ipc call appearance toggleTheme")
bind("SUPER + CTRL + W",     "Background switcher", "quickshell ipc call appearance toggleBackground")
bind("SUPER + CTRL + SPACE", "Background switcher", "quickshell ipc call appearance toggleBackground")

---------------------------------------------------------------
-- Capture
---------------------------------------------------------------
bind("PRINT",                "Screenshot region",        "hypr-screenshot region")
bind("SHIFT + PRINT",        "Screenshot full screen",   "hypr-screenshot screen")
bind("CTRL + PRINT",         "Screenshot window",        "hypr-screenshot window")
bind("SUPER + PRINT",        "Color picker",             "pkill hyprpicker || hyprpicker -a")
bind("SUPER + CTRL + PRINT", "Extract text (OCR)",       "hypr-screenshot ocr")
bind("ALT + PRINT",          "Screen recording toggle",  "hypr-screenshot record")

---------------------------------------------------------------
-- Session
---------------------------------------------------------------
bind("SUPER + ESCAPE",         "System menu", "quickshell ipc call system toggle")
bind("XF86PowerOff",           "System menu", "quickshell ipc call system toggle", { locked = true })
bind("SUPER + CTRL + L",       "Lock screen", "lock-screen")
bind("SUPER + CTRL + ESCAPE",  "Reload config", "hyprctl reload")

---------------------------------------------------------------
-- Media, volume, brightness
---------------------------------------------------------------
local lr = { locked = true, repeating = true }
local l  = { locked = true }

bind("XF86AudioRaiseVolume", "Volume up",   "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", lr)
bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      lr)
bind("XF86AudioMute",        "Mute",        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     l)
bind("XF86AudioMicMute",     "Mute microphone", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", l)
bind("ALT + XF86AudioRaiseVolume", "Volume up (fine)",   "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+", lr)
bind("ALT + XF86AudioLowerVolume", "Volume down (fine)", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-",      lr)

bind("XF86MonBrightnessUp",   "Brightness up",   "brightnessctl -e4 -n2 set 5%+", lr)
bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl -e4 -n2 set 5%-", lr)

bind("XF86AudioNext",  "Next track",     "playerctl next",       l)
bind("XF86AudioPause", "Play/pause",     "playerctl play-pause", l)
bind("XF86AudioPlay",  "Play/pause",     "playerctl play-pause", l)
bind("XF86AudioPrev",  "Previous track", "playerctl previous",   l)
