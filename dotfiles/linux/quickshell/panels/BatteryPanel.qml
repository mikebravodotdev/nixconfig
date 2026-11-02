import QtQuick
import qs.common
import qs.components

// Battery details, plus the batteries of wireless peripherals.
Column {
  id: root
  width: Theme.s(380)

  function levelColor(percent, charging) {
    return charging ? Theme.accent2 : percent <= 15 ? Theme.urgent : Theme.fg
  }

  // ---- main battery
  PanelHeader { text: "Battery"; visible: Battery.hasMain }

  Item {
    visible: Battery.hasMain
    width: parent.width; height: Theme.s(86)

    BatteryIcon {
      id: icon
      anchors { left: parent.left; leftMargin: Theme.s(20); verticalCenter: parent.verticalCenter }
      unit: 2.6 * Theme.uiScale
      fraction: Battery.fraction
      charging: Battery.charging
      color: root.levelColor(Battery.percent, Battery.charging)
    }
    Column {
      anchors { left: icon.right; leftMargin: Theme.s(20); right: parent.right; rightMargin: Theme.s(16); verticalCenter: parent.verticalCenter }
      spacing: 2
      Text {
        text: Battery.percent + "%"
        color: Theme.fgBright
        font { family: Theme.uiFont; pixelSize: Theme.s(34); weight: Font.Light }
      }
      Text {
        width: parent.width
        text: Battery.statusText
        color: Theme.fgDim
        elide: Text.ElideRight
        font { family: Theme.uiFont; pixelSize: Theme.s(13) }
      }
    }
  }

  PanelRow {
    visible: Battery.hasMain && Battery.watts > 0
    glyph: 0xF140B
    title: Battery.charging ? "Charging power" : "Power draw"
    trailing: Battery.watts.toFixed(1) + " W"
    clickable: false
  }
  PanelRow {
    visible: Battery.hasMain && Battery.energyFull > 0
    glyph: 0xF0079
    title: "Energy"
    trailing: Battery.energy.toFixed(1) + " / " + Battery.energyFull.toFixed(1) + " Wh"
    clickable: false
  }
  PanelRow {
    visible: Battery.hasMain && Battery.health > 0
    glyph: 0xF02D1
    title: "Battery health"
    trailing: Math.round(Battery.health) + "%"
    clickable: false
  }

  // ---- peripherals
  PanelHeader { text: "Devices"; visible: Battery.peripherals.length > 0 }
  Repeater {
    model: Battery.peripherals
    delegate: Item {
      required property var modelData
      width: root.width; height: Theme.s(40)
      Text {
        anchors { left: parent.left; leftMargin: Theme.s(18); right: bat.left; rightMargin: Theme.s(10); verticalCenter: parent.verticalCenter }
        text: modelData.name
        elide: Text.ElideRight
        color: Theme.fg
        font { family: Theme.uiFont; pixelSize: Theme.s(14) }
      }
      BatteryIcon {
        id: bat
        anchors { right: pct.left; rightMargin: Theme.s(10); verticalCenter: parent.verticalCenter }
        unit: Theme.uiScale
        fraction: modelData.percent / 100
        color: root.levelColor(modelData.percent, false)
      }
      Text {
        id: pct
        anchors { right: parent.right; rightMargin: Theme.s(18); verticalCenter: parent.verticalCenter }
        width: Theme.s(40)
        horizontalAlignment: Text.AlignRight
        text: modelData.percent + "%"
        color: Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(12) }
      }
    }
  }

  Text {
    visible: !Battery.hasMain && Battery.peripherals.length === 0
    leftPadding: Theme.s(18); topPadding: Theme.s(12); bottomPadding: Theme.s(16)
    text: "No batteries found"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }
  Item { width: 1; height: Theme.s(8) }
}
