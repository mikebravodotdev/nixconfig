import QtQuick
import Quickshell.Bluetooth
import qs.common
import qs.components

// Bluetooth adapter power, scanning, and device connect/disconnect/pair.
Column {
  id: root
  width: Theme.s(400)

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var all: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var known:  all.filter(d => d.paired || d.connected)
  readonly property var nearby: all.filter(d => !(d.paired || d.connected) && (d.name || "") !== "")

  function act(d) {
    if (d.connected) d.disconnect()
    else if (d.paired) d.connect()
    else d.pair()
  }
  function sub(d) {
    var s = d.connected ? "Connected" : d.paired ? "Paired" : "Available"
    if (d.connected && d.batteryAvailable) s += " · " + Math.round(d.battery * 100) + "% battery"
    return s
  }

  PanelHeader {
    text: "Bluetooth"
    visible: root.adapter !== null
    Rectangle {   // scan button
      visible: root.adapter && root.adapter.enabled
      width: scanLabel.implicitWidth + Theme.s(18); height: Theme.s(22); radius: Theme.s(11)
      color: root.adapter && root.adapter.discovering ? Theme.accent : "transparent"
      border { width: 1; color: root.adapter && root.adapter.discovering ? Theme.accent : Theme.tint(0.25) }
      Text {
        id: scanLabel
        anchors.centerIn: parent
        text: root.adapter && root.adapter.discovering ? "Scanning…" : "Scan"
        color: root.adapter && root.adapter.discovering ? Theme.onAccent : Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(11); bold: true }
      }
      MouseArea { anchors.fill: parent; onClicked: root.adapter.discovering = !root.adapter.discovering }
    }
    PanelSwitch {
      checked: root.adapter ? root.adapter.enabled : false
      onToggled: root.adapter.enabled = !root.adapter.enabled
    }
  }

  Text {
    visible: root.adapter === null
    leftPadding: Theme.s(18); topPadding: Theme.s(12); bottomPadding: Theme.s(16)
    text: "No Bluetooth adapter found"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }
  Text {
    visible: root.adapter !== null && !root.adapter.enabled
    leftPadding: Theme.s(18); topPadding: Theme.s(4); bottomPadding: Theme.s(14)
    text: "Bluetooth is off"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }

  Repeater {
    model: root.adapter && root.adapter.enabled ? root.known : []
    delegate: PanelRow {
      required property var modelData
      glyph: modelData.connected ? 0xF00B1 : 0xF00AF
      title: modelData.name || modelData.address
      subtitle: root.sub(modelData)
      active: modelData.connected
      onClicked: root.act(modelData)
    }
  }
  Text {
    visible: root.adapter !== null && root.adapter.enabled && root.known.length === 0
    leftPadding: Theme.s(18); topPadding: Theme.s(4); bottomPadding: Theme.s(10)
    text: "No paired devices. Press Scan to look for some."
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }

  PanelHeader { text: "Nearby"; visible: root.adapter !== null && root.adapter.enabled && root.nearby.length > 0 }
  Repeater {
    model: root.adapter && root.adapter.enabled ? root.nearby.slice(0, 6) : []
    delegate: PanelRow {
      required property var modelData
      glyph: 0xF00AF
      title: modelData.name
      subtitle: "Click to pair"
      onClicked: root.act(modelData)
    }
  }
  Item { width: 1; height: Theme.s(8) }
}
