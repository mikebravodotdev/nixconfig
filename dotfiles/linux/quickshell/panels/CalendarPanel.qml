import QtQuick
import qs.common

// Month calendar. Weeks start on Monday. Click the title to jump back to today.
Column {
  id: root
  width: Theme.s(320)

  property int year: new Date().getFullYear()
  property int month: new Date().getMonth()
  readonly property var names: ["January", "February", "March", "April", "May", "June", "July",
                                "August", "September", "October", "November", "December"]
  readonly property date today: new Date()

  function shift(by) {
    var d = new Date(year, month + by, 1)
    year = d.getFullYear(); month = d.getMonth()
  }

  // 42 cells: { day, month offset (-1, 0, 1) }
  readonly property var cells: {
    var first = new Date(year, month, 1)
    var lead = (first.getDay() + 6) % 7
    var inMonth = new Date(year, month + 1, 0).getDate()
    var prevDays = new Date(year, month, 0).getDate()
    var out = []
    for (var i = 0; i < 42; i++) {
      var n = i - lead + 1
      if (n < 1) out.push({ day: prevDays + n, off: -1 })
      else if (n > inMonth) out.push({ day: n - inMonth, off: 1 })
      else out.push({ day: n, off: 0 })
    }
    return out
  }

  Item {
    width: parent.width; height: Theme.s(48)
    Text {
      id: prev
      anchors { left: parent.left; leftMargin: Theme.s(14); verticalCenter: parent.verticalCenter }
      text: "‹"; color: Theme.fg
      font { family: Theme.uiFont; pixelSize: Theme.s(26) }
      MouseArea { anchors { fill: parent; margins: -8 } onClicked: root.shift(-1) }
    }
    Text {
      anchors.centerIn: parent
      text: root.names[root.month] + " " + root.year
      color: Theme.fg
      font { family: Theme.uiFont; pixelSize: Theme.s(16); bold: true }
      MouseArea {
        anchors { fill: parent; margins: -6 }
        onClicked: { root.year = new Date().getFullYear(); root.month = new Date().getMonth() }
      }
    }
    Text {
      anchors { right: parent.right; rightMargin: Theme.s(14); verticalCenter: parent.verticalCenter }
      text: "›"; color: Theme.fg
      font { family: Theme.uiFont; pixelSize: Theme.s(26) }
      MouseArea { anchors { fill: parent; margins: -8 } onClicked: root.shift(1) }
    }
  }

  Grid {
    x: Theme.s(12)
    columns: 7
    Repeater {
      model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
      delegate: Text {
        required property string modelData
        width: (root.width - Theme.s(24)) / 7; height: Theme.s(24)
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(11); bold: true }
      }
    }
    Repeater {
      model: root.cells
      delegate: Item {
        required property var modelData
        readonly property bool isToday: modelData.off === 0 && modelData.day === root.today.getDate()
                                       && root.month === root.today.getMonth() && root.year === root.today.getFullYear()
        width: (root.width - Theme.s(24)) / 7; height: Theme.s(34)
        Rectangle {
          anchors.centerIn: parent
          width: Theme.s(30); height: Theme.s(30); radius: Theme.s(15)
          color: parent.isToday ? Theme.accent : "transparent"
        }
        Text {
          anchors.centerIn: parent
          text: parent.modelData.day
          color: parent.isToday ? Theme.onAccent : (parent.modelData.off === 0 ? Theme.fg : Theme.tint(0.3))
          font { family: Theme.uiFont; pixelSize: Theme.s(13); bold: parent.isToday }
        }
      }
    }
  }
  Item { width: 1; height: Theme.s(10) }
}
