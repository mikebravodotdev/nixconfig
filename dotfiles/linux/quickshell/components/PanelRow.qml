import QtQuick
import qs.common

// A clickable row: glyph, title, optional subtitle, optional right-hand text.
// `active` marks the current choice (accent bar + bold title).
Item {
  id: root
  property int glyph: 0
  property string title: ""
  property string subtitle: ""
  property string trailing: ""
  property bool active: false
  property bool enabled: true      // false: greyed out
  property bool clickable: true    // false: plain information row
  signal clicked()

  width: parent ? parent.width : 300
  height: subtitle !== "" ? Theme.s(48) : Theme.s(40)

  Rectangle {
    anchors { fill: parent; leftMargin: Theme.s(6); rightMargin: Theme.s(6) }
    radius: Theme.launcherRadius - 4
    color: mouse.containsMouse && root.enabled && root.clickable ? Theme.bgAlt : "transparent"
  }
  Rectangle {   // active marker
    visible: root.active
    anchors { left: parent.left; leftMargin: Theme.s(6); verticalCenter: parent.verticalCenter }
    width: Theme.s(3); height: parent.height - Theme.s(16); radius: 1.5
    color: Theme.accent
  }

  Text {
    id: icon
    visible: root.glyph !== 0
    anchors { left: parent.left; leftMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
    width: Theme.s(22)
    text: root.glyph !== 0 ? Theme.icon(root.glyph) : ""
    color: root.active ? Theme.accent : Theme.fg
    opacity: root.enabled ? 1 : 0.5
    font { family: Theme.uiFont; pixelSize: Theme.s(18) }
  }
  Column {
    anchors {
      left: root.glyph !== 0 ? icon.right : parent.left; leftMargin: root.glyph !== 0 ? Theme.s(10) : Theme.s(18)
      right: tail.left; rightMargin: Theme.s(8)
      verticalCenter: parent.verticalCenter
    }
    spacing: 1
    Text {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      color: Theme.fg
      opacity: root.enabled ? 1 : 0.5
      font { family: Theme.uiFont; pixelSize: Theme.s(14); bold: root.active }
    }
    Text {
      visible: root.subtitle !== ""
      width: parent.width
      text: root.subtitle
      elide: Text.ElideRight
      color: Theme.fgDim
      font { family: Theme.uiFont; pixelSize: Theme.s(11) }
    }
  }
  Text {
    id: tail
    anchors { right: parent.right; rightMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
    text: root.trailing
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(12) }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.clickable
    onClicked: root.clicked()
  }
}
