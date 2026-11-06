import QtQuick
import Quickshell.Io
import qs.common
import qs.components

// CPU details: usage, load, clock, temperature and the busiest processes.
Column {
  id: root
  width: Theme.s(380)

  property real usage: 0
  property string load: "–"
  property string model: ""
  property int cores: 0
  property int mhz: 0
  property int temp: 0
  property var procs: []

  Process {
    id: proc
    command: ["sh", "-c",
      "awk '{print \"load \"$1\" \"$2\" \"$3}' /proc/loadavg; " +
      "awk -F: '/model name/{print \"model \"$2; exit}' /proc/cpuinfo; " +
      "echo cores $(nproc); " +
      "awk '/cpu MHz/{s+=$4;n++}END{if(n)printf \"mhz %d\\n\", s/n}' /proc/cpuinfo; " +
      "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in k10temp|coretemp|zenpower) " +
      "echo temp $(( $(cat $h/temp1_input) / 1000 )); break;; esac; done; " +
      "top -bn2 -d0.5 -w256 | awk '/^top -/{n=0} /^%Cpu/{if(match($0,/[0-9.]+ id/))idle=substr($0,RSTART,RLENGTH-3)} " +
      "$1 ~ /^[0-9]+$/ && n<5 {n++; p[n]=\"proc \"$9\"|\"$10\"|\"$12} " +
      "END{printf \"usage %.0f\\n\", 100-idle; for(i=1;i<=n;i++)print p[i]}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var list = []
        text.split("\n").forEach(l => {
          if (l.startsWith("load ")) root.load = l.slice(5).replace(/ /g, "  ")
          else if (l.startsWith("model ")) root.model = l.slice(6).trim()
          else if (l.startsWith("cores ")) root.cores = parseInt(l.slice(6))
          else if (l.startsWith("mhz ")) root.mhz = parseInt(l.slice(4))
          else if (l.startsWith("temp ")) root.temp = parseInt(l.slice(5))
          else if (l.startsWith("usage ")) root.usage = parseFloat(l.slice(6))
          else if (l.startsWith("proc ")) list.push(l.slice(5).split("|"))
        })
        root.procs = list
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!proc.running) proc.running = true }

  PanelHeader { text: "CPU" }

  Item {
    width: parent.width; height: Theme.s(86)
    Text {
      id: big
      anchors { left: parent.left; leftMargin: Theme.s(20); verticalCenter: parent.verticalCenter }
      text: Math.round(root.usage) + "%"
      color: root.usage > 85 ? Theme.urgent : Theme.fgBright
      font { family: Theme.uiFont; pixelSize: Theme.s(34); weight: Font.Light }
    }
    Column {
      anchors { left: big.right; leftMargin: Theme.s(20); right: parent.right; rightMargin: Theme.s(16); verticalCenter: parent.verticalCenter }
      spacing: Theme.s(6)
      Text {
        width: parent.width
        text: root.model
        elide: Text.ElideRight
        color: Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(12) }
      }
      MeterBar { width: parent.width; fraction: root.usage / 100 }
    }
  }

  PanelRow { glyph: 0xF0EE0; title: "Load average"; trailing: root.load; clickable: false }
  PanelRow { visible: root.cores > 0; glyph: 0xF061A; title: "Threads"; trailing: root.cores; clickable: false }
  PanelRow { visible: root.mhz > 0; glyph: 0xF04C5; title: "Clock"; trailing: (root.mhz / 1000).toFixed(2) + " GHz"; clickable: false }
  PanelRow { visible: root.temp > 0; glyph: 0xF050F; title: "Temperature"; trailing: root.temp + " °C"; clickable: false }

  PanelHeader { text: "Top processes"; visible: root.procs.length > 0 }
  Repeater {
    model: root.procs
    delegate: PanelRow {
      required property var modelData
      title: modelData[2]
      trailing: modelData[0] + "% CPU"
      clickable: false
    }
  }
  Item { width: 1; height: Theme.s(8) }
}
