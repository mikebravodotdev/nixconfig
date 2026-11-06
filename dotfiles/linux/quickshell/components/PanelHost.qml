import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.panels

// Hosts whichever bar popup is open (Panels.current), hanging under the bar
// near the widget that opened it. Clicking outside or pressing Esc closes it.
Scope {
  PanelWindow {
    id: win
    visible: Panels.current !== ""

    screen: {
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === Panels.screenName) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    margins { top: Theme.barHeight }      // leave the bar itself clickable
    color: "transparent"

    onVisibleChanged: if (visible) keys.forceActiveFocus()

    MouseArea { anchors.fill: parent; onClicked: Panels.close() }

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: Panels.close()
    }

    Rectangle {
      id: card
      width: loader.item ? loader.item.width : 0
      height: loader.item ? loader.item.height : 0
      x: Math.max(10, Math.min(win.width - width - 10, Panels.anchorX - width / 2))
      y: Theme.s(6)
      radius: Theme.launcherRadius
      color: Theme.card
      border { width: 1; color: Theme.tint(0.2) }
      clip: true

      MouseArea { anchors.fill: parent }     // swallow clicks inside the card

      Loader {
        id: loader
        sourceComponent: ({
          audio: audio, network: network, bluetooth: bluetooth, power: power, calendar: calendar,
          notifications: notifications, battery: battery, cpu: cpu, memory: memory
        })[Panels.current]
      }
    }

    Component { id: audio;     AudioPanel {} }
    Component { id: network;   NetworkPanel {} }
    Component { id: bluetooth; BluetoothPanel {} }
    Component { id: power;     PowerPanel {} }
    Component { id: calendar;  CalendarPanel {} }
    Component { id: notifications; NotificationsPanel {} }
    Component { id: battery;   BatteryPanel {} }
    Component { id: cpu;       CpuPanel {} }
    Component { id: memory;    MemoryPanel {} }
  }
}
