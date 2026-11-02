import QtQuick
import QtQuick.Shapes
import qs.common

// A battery drawn from shapes: outline, level fill, terminal nub, and a bolt while charging.
// `unit` scales it (1 = 24x12 px body).
Item {
  id: root
  property real fraction: 0
  property bool charging: false
  property color color: Theme.fg
  property real unit: 1

  implicitWidth: 26 * unit
  implicitHeight: 12 * unit

  Rectangle {   // body outline
    id: body
    width: 24 * root.unit; height: 12 * root.unit
    radius: 2.5 * root.unit
    color: "transparent"
    border { width: Math.max(1, Math.round(root.unit)); color: root.color }

    Rectangle {   // level
      x: 2 * root.unit; y: 2 * root.unit
      width: Math.max(0, (parent.width - 4 * root.unit) * Math.max(0, Math.min(1, root.fraction)))
      height: parent.height - 4 * root.unit
      radius: 1 * root.unit
      color: root.color
    }
  }
  Rectangle {   // nub
    x: 24.5 * root.unit
    anchors.verticalCenter: body.verticalCenter
    width: 2 * root.unit; height: 5 * root.unit
    radius: 1 * root.unit
    color: root.color
  }
  Shape {       // bolt
    visible: root.charging
    anchors.centerIn: body
    width: 9 * root.unit; height: 12 * root.unit
    ShapePath {
      strokeWidth: Math.max(1, root.unit * 0.9)
      strokeColor: Theme.bgDark
      fillColor: Theme.fgBright
      joinStyle: ShapePath.RoundJoin
      PathPolyline {
        path: [
          Qt.point(5.6 * root.unit, 1), Qt.point(1.2 * root.unit, 6.4 * root.unit), Qt.point(4.1 * root.unit, 6.4 * root.unit),
          Qt.point(3.2 * root.unit, 11 * root.unit), Qt.point(7.8 * root.unit, 5.0 * root.unit), Qt.point(4.9 * root.unit, 5.0 * root.unit),
          Qt.point(5.6 * root.unit, 1)
        ]
      }
    }
  }
}
