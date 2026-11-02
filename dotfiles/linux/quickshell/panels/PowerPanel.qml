import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components

// Power profile (power-profiles-daemon).
Column {
  id: root
  width: Theme.s(320)

  property string current: ""
  property var available: []

  Process {
    id: getProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector { onStreamFinished: root.current = text.trim() }
  }
  Process {
    id: listProc
    command: ["powerprofilesctl", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        var names = []
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var m = /^[\s*]*([a-z-]+):\s*$/.exec(lines[i])
          if (m) names.push(m[1])
        }
        root.available = names
      }
    }
  }
  Component.onCompleted: { getProc.running = true; listProc.running = true }

  function set(name) {
    Quickshell.execDetached(["powerprofilesctl", "set", name])
    current = name
  }

  readonly property var meta: ({
    "performance": { title: "Performance",  sub: "Maximum speed, more heat and noise", glyph: 0xF04C5 },
    "balanced":    { title: "Balanced",     sub: "Good speed with sensible power use",  glyph: 0xF05D1 },
    "power-saver": { title: "Power Saver",  sub: "Lower speed, quieter and cooler",     glyph: 0xF032A }
  })

  PanelHeader { text: "Power profile" }
  Repeater {
    model: root.available
    delegate: PanelRow {
      required property string modelData
      glyph: root.meta[modelData] ? root.meta[modelData].glyph : 0xF0425
      title: root.meta[modelData] ? root.meta[modelData].title : modelData
      subtitle: root.meta[modelData] ? root.meta[modelData].sub : ""
      active: root.current === modelData
      onClicked: root.set(modelData)
    }
  }
  Text {
    visible: root.available.length === 0
    leftPadding: Theme.s(18); bottomPadding: Theme.s(14)
    text: "power-profiles-daemon is not running"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }
  Item { width: 1; height: Theme.s(8) }
}
