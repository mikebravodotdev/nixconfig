import QtQuick
import Quickshell
import qs.common
import qs.components

// Notification history: newest first, with do-not-disturb and clear-all.
// Click an entry (or its ×) to remove it.
Column {
  id: root
  width: Theme.s(440)

  property real now: Date.now()
  Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

  // Opening the panel reads everything; so does anything arriving while it is open.
  Component.onCompleted: NotificationHistory.markRead()
  Connections { target: NotificationHistory; function onEntriesChanged() { NotificationHistory.markRead() } }

  function rel(ms) {
    var s = Math.max(0, (now - ms) / 1000)
    if (s < 60) return "now"
    if (s < 3600) return Math.floor(s / 60) + "m"
    if (s < 86400) return Math.floor(s / 3600) + "h"
    return Qt.formatDate(new Date(ms), "d MMM")
  }

  // ---- header
  PanelHeader {
    text: "Notifications"
    Text {
      visible: NotificationHistory.entries.length > 0
      text: "Clear all"
      color: Theme.accent
      font { family: Theme.uiFont; pixelSize: Theme.s(12); bold: true }
      MouseArea { anchors { fill: parent; margins: -6 } onClicked: NotificationHistory.clear() }
    }
  }
  Item {
    width: parent.width; height: Theme.s(40)
    Text {
      anchors { left: parent.left; leftMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
      text: Theme.icon(NotificationHistory.dnd ? 0xF009B : 0xF009C) + "   Do not disturb"
      color: Theme.fg
      font { family: Theme.uiFont; pixelSize: Theme.s(14) }
    }
    PanelSwitch {
      anchors { right: parent.right; rightMargin: Theme.s(16); verticalCenter: parent.verticalCenter }
      checked: NotificationHistory.dnd
      onToggled: NotificationHistory.setDnd(!NotificationHistory.dnd)
    }
  }
  Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13) }

  // ---- empty state
  Text {
    visible: NotificationHistory.entries.length === 0
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: Theme.s(36); bottomPadding: Theme.s(40)
    text: "No notifications"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(14) }
  }

  // ---- list
  ListView {
    id: list
    visible: count > 0
    width: parent.width
    height: Math.min(contentHeight, Theme.s(520))
    clip: true
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    model: NotificationHistory.entries

    delegate: Item {
      id: row
      required property var modelData
      width: list.width
      height: body.implicitHeight + Theme.s(22)

      Rectangle {
        anchors { fill: parent; leftMargin: Theme.s(6); rightMargin: Theme.s(6) }
        radius: Theme.launcherRadius - 4
        color: hover.containsMouse ? Theme.bgAlt : "transparent"
      }
      Rectangle {   // urgency marker
        visible: row.modelData.urgency === 2
        anchors { left: parent.left; leftMargin: Theme.s(6); verticalCenter: parent.verticalCenter }
        width: Theme.s(3); height: parent.height - Theme.s(16); radius: 1.5
        color: Theme.urgent
      }

      Image {
        id: appIcon
        anchors { left: parent.left; leftMargin: Theme.s(18); top: parent.top; topMargin: Theme.s(12) }
        width: Theme.s(26); height: Theme.s(26)
        sourceSize: Qt.size(Theme.s(26), Theme.s(26))
        visible: status === Image.Ready
        source: row.modelData.icon !== "" ? Quickshell.iconPath(row.modelData.icon, true) : ""
      }
      Text {
        anchors.centerIn: appIcon
        visible: appIcon.status !== Image.Ready
        text: Theme.icon(0xF009C)
        color: Theme.accent
        font { family: Theme.uiFont; pixelSize: Theme.s(20) }
      }

      Column {
        id: body
        anchors { left: appIcon.right; leftMargin: Theme.s(12); right: side.left; rightMargin: Theme.s(10); top: parent.top; topMargin: Theme.s(11) }
        spacing: 2
        Text {
          width: parent.width
          text: row.modelData.app
          visible: text !== ""
          elide: Text.ElideRight
          color: Theme.fgDim
          font { family: Theme.uiFont; pixelSize: Theme.s(11) }
        }
        Text {
          width: parent.width
          text: row.modelData.summary
          elide: Text.ElideRight
          maximumLineCount: 1
          color: Theme.fg
          font { family: Theme.uiFont; pixelSize: Theme.s(14); bold: true }
        }
        Text {
          width: parent.width
          visible: text !== ""
          text: row.modelData.body
          textFormat: Text.StyledText
          wrapMode: Text.Wrap
          maximumLineCount: 3
          elide: Text.ElideRight
          color: Theme.tint(0.75)
          font { family: Theme.uiFont; pixelSize: Theme.s(13) }
        }
      }

      Column {
        id: side
        anchors { right: parent.right; rightMargin: Theme.s(18); top: parent.top; topMargin: Theme.s(12) }
        spacing: Theme.s(4)
        Text {
          anchors.right: parent.right
          text: root.rel(row.modelData.time)
          color: Theme.fgDim
          font { family: Theme.uiFont; pixelSize: Theme.s(11) }
        }
        Text {
          anchors.right: parent.right
          text: "×"
          visible: hover.containsMouse
          color: Theme.fg
          font { family: Theme.uiFont; pixelSize: Theme.s(18) }
        }
      }

      MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: NotificationHistory.remove(row.modelData.id)
      }
    }
  }
  Item { width: 1; height: Theme.s(8) }
}
