pragma Singleton
import QtQuick
import Quickshell

// Session and power actions, shared by the system menu and the launcher.
// key: hotkey in the menu. confirm: needs a second press. menu: show as a menu tile.
Singleton {
  readonly property var list: [
    { id: "sys:lock",     title: "Lock",     subtitle: "Lock the screen",              glyph: 0xF033E, key: "L", menu: true,
      cmd: ["loginctl", "lock-session"] },
    { id: "sys:suspend",  title: "Sleep",    subtitle: "Suspend to RAM",               glyph: 0xF04B2, key: "S", menu: true,
      cmd: ["systemctl", "suspend"] },
    { id: "sys:logout",   title: "Log Out",  subtitle: "End the Hyprland session",     glyph: 0xF0343, key: "O", menu: true, confirm: true,
      cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
    { id: "sys:reboot",   title: "Restart",  subtitle: "Reboot the computer",          glyph: 0xF0709, key: "R", menu: true, confirm: true,
      cmd: ["systemctl", "reboot"] },
    { id: "sys:shutdown", title: "Shut Down", subtitle: "Power off the computer",      glyph: 0xF0425, key: "D", menu: true, confirm: true,
      cmd: ["systemctl", "poweroff"] },
    { id: "sys:reload",   title: "Reload Hyprland", subtitle: "Re-read the Hyprland config", glyph: 0xF0450, key: "", menu: false,
      cmd: ["hyprctl", "reload"] }
  ]
}
