//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components
import qs.services

ShellRoot {
  // Wallpaper on every monitor (follows the active theme).
  Variants {
    model: Quickshell.screens
    Wallpaper {
      required property var modelData
      screen: modelData
    }
  }

  // Bar on every monitor.
  property bool barVisible: true
  Variants {
    model: Quickshell.screens
    Bar {
      required property var modelData
      screen: modelData
      visible: barVisible
    }
  }

  // Notification daemon and toasts (owns org.freedesktop.Notifications).
  Notifications { id: notifications }

  // App launcher (Super+Space).
  Launcher { id: launcher }

  // Clipboard history panel (Super+Ctrl+V).
  Clipboard { id: clipboard }

  // System menu: lock, sleep, log out, restart, shut down (Super+Escape).
  SystemMenu { id: systemMenu }

  // Theme and wallpaper switcher (Super+Ctrl+T / Super+Ctrl+W).
  Appearance { id: appearance }

  // Keybinding cheat sheet (Super+K).
  Cheatsheet { id: cheatsheet }

  // Popups opened from the bar: audio, network, bluetooth, power, calendar.
  PanelHost {}

  // Lock screen (ext-session-lock + PAM). Lock with `lock-screen`.
  Lock { id: lockScreen }

  // Volume / brightness style on-screen display.
  VolumeOsd {}

  // Control from the Hyprland config: `quickshell ipc call <target> <function>`.
  IpcHandler {
    target: "bar"
    function toggle(): void { barVisible = !barVisible }
  }
  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
    function present(): void { launcher.show() }
    function dismiss(): void { launcher.hide() }
    function query(text: string): void { launcher.query(text) }
  }
  IpcHandler {
    target: "clipboard"
    function toggle(): void { clipboard.toggle() }
    function present(): void { clipboard.show() }
    function dismiss(): void { clipboard.hide() }
  }
  IpcHandler {
    target: "system"
    function toggle(): void { systemMenu.toggle() }
    function present(): void { systemMenu.show() }
    function dismiss(): void { systemMenu.hide() }
  }
  IpcHandler {
    target: "appearance"
    function toggleTheme(): void { appearance.toggle("theme") }
    function toggleBackground(): void { appearance.toggle("background") }
    function dismiss(): void { appearance.hide() }
  }
  IpcHandler {
    target: "cheatsheet"
    function toggle(): void { cheatsheet.toggle() }
    function present(): void { cheatsheet.show() }
    function dismiss(): void { cheatsheet.hide() }
  }
  IpcHandler {
    target: "panels"
    // e.g. `quickshell ipc call panels toggle audio`; opens near the right of the bar.
    function toggle(name: string): void { Panels.toggle(name, Quickshell.screens[0].width - 260, Quickshell.screens[0].name) }
    function close(): void { Panels.close() }
  }
  IpcHandler {
    target: "lock"
    function lock(): void { lockScreen.lock() }
    function isLocked(): bool { return lockScreen.locked }
  }
  // Preview the battery UI without a battery: `battery mock 42 discharging|charging|full`,
  // `battery peripherals true`, `battery off`. Display only; it changes nothing real.
  IpcHandler {
    target: "battery"
    function mock(percent: int, state: string): void {
      Battery.mock = { main: true, percent: percent, state: state, seconds: state === "discharging" ? 11520 : 2700,
                       watts: state === "discharging" ? 8.4 : 31.5, health: 91, energy: 58 * percent / 100, energyFull: 58,
                       peripherals: Battery.mock ? Battery.mock.peripherals : [] }
    }
    function peripherals(on: bool): void {
      var m = Battery.mock ? Object.assign({}, Battery.mock) : { main: false, percent: 0, state: "unknown" }
      m.peripherals = on ? [{ id: "a", name: "MX Master 3S", percent: 43, kind: "mouse" }, { id: "b", name: "Keychron K8", percent: 12, kind: "keyboard" }] : []
      Battery.mock = m
    }
    function off(): void { Battery.mock = null }
  }
  IpcHandler {
    target: "notifications"
    function dismissAll(): void { notifications.dismissAll() }
    function dismissOne(): void { notifications.dismissLast() }
    function toggleDnd(): void { NotificationHistory.setDnd(!NotificationHistory.dnd) }
    function clearHistory(): void { NotificationHistory.clear() }
  }
}
