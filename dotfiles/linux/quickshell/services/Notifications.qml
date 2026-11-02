import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.common

// Owns org.freedesktop.Notifications and shows toasts top-right on the
// focused monitor. Click a toast to dismiss it.
Item {
  id: root

  function dismissAll() {
    var vals = server.trackedNotifications.values.slice()
    for (var i = 0; i < vals.length; i++) vals[i].dismiss()
  }
  function dismissLast() {
    var vals = server.trackedNotifications.values
    if (vals.length > 0) vals[vals.length - 1].dismiss()
  }

  NotificationServer {
    id: server
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    onNotification: n => {
      NotificationHistory.add(n)
      // Do not disturb: kept in the history, but no toast (critical ones still show).
      if (NotificationHistory.dnd && n.urgency !== NotificationUrgency.Critical) return
      n.tracked = true
    }
  }

  PanelWindow {
    id: win

    // Follow the focused monitor, falling back to the first screen.
    screen: {
      var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    visible: server.trackedNotifications.values.length > 0
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + Theme.gap; right: Theme.gap }
    implicitWidth: Theme.s(380)
    implicitHeight: stack.implicitHeight
    color: "transparent"

    Column {
      id: stack
      width: parent.width
      spacing: Theme.s(8)

      Repeater {
        model: server.trackedNotifications
        delegate: Rectangle {
          id: toast
          required property var modelData
          readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

          width: stack.width
          implicitHeight: content.implicitHeight + Theme.s(24)
          color: Theme.bg
          border.width: 2
          border.color: critical ? Theme.urgent : Theme.border

          Column {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s(12) }
            spacing: Theme.s(4)

            Text {
              width: parent.width
              text: toast.modelData.appName
              visible: text !== ""
              color: Theme.fgDim
              elide: Text.ElideRight
              font { family: Theme.font; pixelSize: Theme.fontSize - 2 }
            }
            Text {
              width: parent.width
              text: toast.modelData.summary
              color: Theme.fg
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              font { family: Theme.font; pixelSize: Theme.fontSize; bold: true }
            }
            Text {
              width: parent.width
              text: toast.modelData.body
              visible: text !== ""
              color: Theme.fg
              textFormat: Text.StyledText
              wrapMode: Text.Wrap
              maximumLineCount: 6
              elide: Text.ElideRight
              font { family: Theme.font; pixelSize: Theme.fontSize }
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: toast.modelData.dismiss()
          }

          // Auto-expire: honour the sender's timeout, default 6 s; critical stays.
          Timer {
            running: !toast.critical
            interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 6000
            onTriggered: toast.modelData.expire()
          }
        }
      }
    }
  }
}
