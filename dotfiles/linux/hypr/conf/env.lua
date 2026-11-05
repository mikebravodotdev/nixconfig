-- Environment. See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Prefer Wayland everywhere, falling back to X11 where an app needs it.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

-- Needed for screen sharing and the right portal.
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Flatpak exports (.desktop files, icons) so the launcher lists Flatpak apps.
-- Debian has no host flatpak to add this at login (NixOS already does; harmless there).
hl.env("XDG_DATA_DIRS", os.getenv("HOME") .. "/.local/share/flatpak/exports/share:" .. (os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"))

-- ~/.local/bin for the helper scripts (screenshot, etc.).
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"))

hl.config({
  xwayland = {
    -- Don't let the compositor blur-scale X11 apps.
    force_zero_scaling = true,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})

-- Icon theme for Quickshell (launcher, tray).
hl.env("QS_ICON_THEME", "breeze")
