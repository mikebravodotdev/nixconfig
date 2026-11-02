import QtQuick
import qs.common

// Small section title with an optional right-hand control slot.
Item {
  id: root
  property string text: ""
  default property alias trailing: slot.data
  width: parent ? parent.width : 300
  height: Theme.s(34)

  Text {
    anchors { left: parent.left; leftMargin: Theme.s(16); verticalCenter: parent.verticalCenter }
    text: root.text.toUpperCase()
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(11); bold: true; letterSpacing: 1 }
  }
  Row {
    id: slot
    anchors { right: parent.right; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
    spacing: Theme.s(8)
  }
}
