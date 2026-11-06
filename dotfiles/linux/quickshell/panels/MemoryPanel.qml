import QtQuick
import Quickshell.Io
import qs.common
import qs.components

// Memory details: used/total, cache, swap and the hungriest processes.
Column {
  id: root
  width: Theme.s(380)

  property real total: 0      // all values in kB
  property real avail: 0
  property real cached: 0
  property real swapTotal: 0
  property real swapFree: 0
  property var procs: []

  readonly property real used: total - avail
  readonly property real fraction: total > 0 ? used / total : 0

  function gb(kb) { return (kb / 1048576).toFixed(1) + " GB" }
  function mb(kb) { return kb >= 1048576 ? gb(kb) : Math.round(kb / 1024) + " MB" }

  Process {
    id: proc
    command: ["sh", "-c",
      "grep -E '^(MemTotal|MemAvailable|Cached|SwapTotal|SwapFree):' /proc/meminfo; " +
      "ps -eo rss=,comm= --sort=-rss | head -5 | awk '{print \"proc \"$1\" \"$2}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var list = []
        text.split("\n").forEach(l => {
          var m = l.match(/^(\w+):\s+(\d+)/)
          if (m) {
            var v = Number(m[2])
            if (m[1] === "MemTotal") root.total = v
            else if (m[1] === "MemAvailable") root.avail = v
            else if (m[1] === "Cached") root.cached = v
            else if (m[1] === "SwapTotal") root.swapTotal = v
            else if (m[1] === "SwapFree") root.swapFree = v
          } else if (l.startsWith("proc ")) {
            var p = l.slice(5).split(" ")
            list.push([Number(p[0]), p.slice(1).join(" ")])
          }
        })
        root.procs = list
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!proc.running) proc.running = true }

  PanelHeader { text: "Memory" }

  Item {
    width: parent.width; height: Theme.s(86)
    Text {
      id: big
      anchors { left: parent.left; leftMargin: Theme.s(20); verticalCenter: parent.verticalCenter }
      text: Math.round(root.fraction * 100) + "%"
      color: root.fraction > 0.9 ? Theme.urgent : Theme.fgBright
      font { family: Theme.uiFont; pixelSize: Theme.s(34); weight: Font.Light }
    }
    Column {
      anchors { left: big.right; leftMargin: Theme.s(20); right: parent.right; rightMargin: Theme.s(16); verticalCenter: parent.verticalCenter }
      spacing: Theme.s(6)
      Text {
        width: parent.width
        text: root.gb(root.used) + " of " + root.gb(root.total)
        elide: Text.ElideRight
        color: Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(12) }
      }
      MeterBar { width: parent.width; fraction: root.fraction; warn: 0.9 }
    }
  }

  PanelRow { glyph: 0xF035B; title: "Available"; trailing: root.gb(root.avail); clickable: false }
  PanelRow { glyph: 0xF035B; title: "Cached"; trailing: root.gb(root.cached); clickable: false }
  PanelRow {
    visible: root.swapTotal > 0
    glyph: 0xF035B
    title: "Swap"
    trailing: root.gb(root.swapTotal - root.swapFree) + " / " + root.gb(root.swapTotal)
    clickable: false
  }

  PanelHeader { text: "Top processes"; visible: root.procs.length > 0 }
  Repeater {
    model: root.procs
    delegate: PanelRow {
      required property var modelData
      title: modelData[1]
      trailing: root.mb(modelData[0])
      clickable: false
    }
  }
  Item { width: 1; height: Theme.s(8) }
}
