import QtQuick
import qs.common

// Horizontal 0..1 slider with a glyph button on the left and a percentage on the right.
Item {
  id: root
  property real value: 0
  property bool muted: false
  property int glyph: 0xF057E
  signal moved(real v)          // dragged or clicked to a new value
  signal glyphClicked()         // e.g. mute toggle

  width: parent ? parent.width : 300
  height: Theme.s(44)

  Text {
    id: btn
    anchors { left: parent.left; leftMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
    width: Theme.s(24)
    text: Theme.icon(root.glyph)
    color: root.muted ? Theme.fgDim : Theme.fg
    font { family: Theme.uiFont; pixelSize: Theme.s(20) }
    MouseArea { anchors { fill: parent; margins: -6 } onClicked: root.glyphClicked() }
  }

  Item {
    id: track
    anchors { left: btn.right; leftMargin: Theme.s(12); right: pct.left; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
    height: Theme.s(20)

    Rectangle {
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
      height: Theme.s(6); radius: Theme.s(3)
      color: Theme.bgAlt
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height; radius: Theme.s(3)
        color: root.muted ? Theme.fgDim : Theme.accent
      }
    }
    Rectangle {   // handle
      x: (track.width - width) * Math.max(0, Math.min(1, root.value))
      anchors.verticalCenter: parent.verticalCenter
      width: Theme.s(14); height: Theme.s(14); radius: Theme.s(7)
      color: root.muted ? Theme.fgDim : Theme.fgBright
    }
    MouseArea {
      anchors.fill: parent
      function setFrom(mx) { root.moved(Math.max(0, Math.min(1, mx / width))) }
      onPressed: mouse => setFrom(mouse.x)
      onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
      onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
  }

  Text {
    id: pct
    anchors { right: parent.right; rightMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
    width: Theme.s(38)
    horizontalAlignment: Text.AlignRight
    text: Math.round(root.value * 100) + "%"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(12) }
  }
}
