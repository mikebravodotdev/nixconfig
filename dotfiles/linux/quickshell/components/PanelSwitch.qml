import QtQuick
import qs.common

// Small on/off switch.
Rectangle {
  id: root
  property bool checked: false
  signal toggled()
  width: Theme.s(38); height: Theme.s(20); radius: Theme.s(10)
  color: checked ? Theme.accent : Theme.bgAlt
  border { width: 1; color: checked ? Theme.accent : Theme.tint(0.25) }
  Rectangle {
    x: root.checked ? parent.width - width - Theme.s(3) : Theme.s(3)
    anchors.verticalCenter: parent.verticalCenter
    width: Theme.s(14); height: Theme.s(14); radius: Theme.s(7)
    color: root.checked ? Theme.onAccent : Theme.fgDim
    Behavior on x { NumberAnimation { duration: 90 } }
  }
  MouseArea { anchors.fill: parent; onClicked: root.toggled() }
}
