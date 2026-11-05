-- Autostart. See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Bar and notifications come from Quickshell; a wallpaper daemon is still to do.

hl.on("hyprland.start", function()
  -- Write the palette state (state.json, hyprlock/hyprland theme files,
  -- kitty/foot colors) before anything below reads it. `--init` only touches
  -- state if no theme has ever been applied, so this is a no-op after the
  -- first login and safe to run every session.
  hl.exec_cmd("theme-apply --init")

  -- Make the session environment visible to systemd and D-Bus activated apps
  -- (the "slow app launch" fix).
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- Polkit prompts and idle/lock handling.
  hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
  hl.exec_cmd("systemctl --user restart hypridle.service")

  -- The desktop shell: bar, notification daemon, volume OSD (~/.config/quickshell).
  hl.exec_cmd("quickshell")

  -- Clipboard history for cliphist (text and images).
  hl.exec_cmd("wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
