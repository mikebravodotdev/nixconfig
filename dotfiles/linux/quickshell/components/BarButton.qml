import QtQuick
import Quickshell
import qs.common

// A bar item that opens a popup panel when clicked. Put a Text (or anything) inside.
Item {
  id: btn
  property string panel: ""
  default property alias content: holder.data
  signal clicked(var mouse)
  signal wheel(var event)

  implicitWidth: holder.implicitWidth + 14
  implicitHeight: 28

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: mouse.containsMouse || (btn.panel !== "" && Panels.current === btn.panel) ? Theme.tint(0.1) : "transparent"
  }
  Row { id: holder; anchors.centerIn: parent; spacing: 6 }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: m => {
      btn.clicked(m)
      if (btn.panel !== "" && m.button === Qt.LeftButton) {
        var win = btn.QsWindow.window
        Panels.toggle(btn.panel, btn.mapToItem(null, btn.width / 2, 0).x, win && win.screen ? win.screen.name : "")
      }
    }
    onWheel: w => btn.wheel(w)
  }
}
