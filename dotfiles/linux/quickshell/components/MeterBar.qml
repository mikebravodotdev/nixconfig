import QtQuick
import qs.common

// Thin horizontal usage bar. fraction is 0..1; turns urgent above `warn`.
Rectangle {
  property real fraction: 0
  property real warn: 0.85
  height: Theme.s(6)
  radius: height / 2
  color: Theme.bgAlt
  Rectangle {
    width: parent.width * Math.max(0, Math.min(1, parent.fraction))
    height: parent.height
    radius: parent.radius
    color: parent.fraction > parent.warn ? Theme.urgent : Theme.accent
    Behavior on width { NumberAnimation { duration: 200 } }
  }
}
