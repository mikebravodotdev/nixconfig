pragma Singleton
import QtQuick
import Quickshell

// Which bar popup is open, and where it hangs from.
Singleton {
  property string current: ""      // "audio" | "network" | "bluetooth" | "power" | "calendar" | ""
  property real anchorX: 0         // screen x the popup should centre on
  property string screenName: ""

  function toggle(name, x, screen) {
    if (current === name && screenName === screen) { current = ""; return }
    current = name
    anchorX = x
    screenName = screen
  }
  function close() { current = "" }
}
