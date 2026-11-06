import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import qs.components
import qs.common

PanelWindow {
  id: bar

  WlrLayershell.namespace: "qs-bar"
  anchors { top: true; left: true; right: true }
  implicitHeight: Theme.barHeight
  color: Theme.bg

  // Bar text size, scaled like the panels.
  readonly property int fs: Theme.s(Theme.fontSize)

  // ------------------------------------------------------------ state
  readonly property var monitor: Hyprland.monitorFor(bar.screen)
  readonly property int activeWs: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

  function wsExists(id) {
    var vals = Hyprland.workspaces.values
    for (var i = 0; i < vals.length; i++) if (vals[i].id === id) return true
    return false
  }

  function dispatch(expr) { Hyprland.dispatch(expr) }

  // Default audio sink; the tracker keeps its properties live.
  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: [bar.sink] }
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted:  sink && sink.audio ? sink.audio.muted : false

  // ------------------------------------------------------------ power profile, bluetooth
  property string profile: "balanced"
  Process {
    id: profProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector { onStreamFinished: bar.profile = text.trim() }
  }
  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: profProc.running = true }
  // Re-read right after a panel closes (a profile may have changed).
  Connections { target: Panels; function onCurrentChanged() { profProc.running = true } }

  readonly property int btConnected: {
    var v = Bluetooth.devices ? Bluetooth.devices.values : []
    var n = 0
    for (var i = 0; i < v.length; i++) if (v[i].connected) n++
    return n
  }

  // ------------------------------------------------------------ system stats
  property int cpuPct: 0
  property int memPct: 0
  property real _idle: 0
  property real _total: 0

  Process {
    id: stats
    command: ["sh", "-c",
      "head -1 /proc/stat; awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"mem %d\\n\", (t-a)*100/t}' /proc/meminfo"]
    stdout: SplitParser {
      onRead: line => {
        if (line.startsWith("cpu ")) {
          var f = line.trim().split(/\s+/).slice(1).map(Number)
          var idle = f[3] + f[4]
          var total = f.reduce((a, b) => a + b, 0)
          if (bar._total > 0 && total > bar._total)
            bar.cpuPct = Math.round(100 * (1 - (idle - bar._idle) / (total - bar._total)))
          bar._idle = idle
          bar._total = total
        } else if (line.startsWith("mem ")) {
          bar.memPct = parseInt(line.slice(4))
        }
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: stats.running = true }

  // ------------------------------------------------------------ network
  property string netLabel: "…"
  Process {
    id: net
    command: ["sh", "-c",
      "nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$2==\"connected\"{print $1\":\"$3; exit}'"]
    stdout: SplitParser {
      onRead: line => {
        var p = line.split(":")
        if (p[0] === "wifi") bar.netLabel = Theme.icon(0xF05A9) + "  " + p[1]
        else if (p[0] === "ethernet") bar.netLabel = Theme.icon(0xF0200) + "  " + p[1]
        else bar.netLabel = Theme.icon(0xF05AA) + "  offline"
      }
    }
    onExited: if (netLabel === "…") netLabel = Theme.icon(0xF05AA) + "  offline"
  }
  Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: net.running = true }

  // ------------------------------------------------------------ layout
  Rectangle {
    anchors.fill: parent
    color: Theme.bg

    // thin accent line along the bottom edge
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: 1
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Theme.accent }
        GradientStop { position: 1; color: Theme.accent2 }
      }
      opacity: 0.6
    }

    // ---- left: workspaces
    Row {
      anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
      spacing: 2

      Repeater {
        model: 10
        delegate: Rectangle {
          required property int index
          readonly property int wsId: index + 1
          readonly property bool active: bar.activeWs === wsId
          readonly property bool occupied: bar.wsExists(wsId)
          visible: active || occupied || wsId <= 5
          width: Theme.s(30); height: Theme.s(26)
          color: active ? Theme.accent : "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.wsId === 10 ? "0" : parent.wsId
            color: parent.active ? Theme.onAccent : (parent.occupied ? Theme.fg : Theme.fgDim)
            font { family: Theme.font; pixelSize: bar.fs; bold: parent.active }
          }
          MouseArea {
            anchors.fill: parent
            onClicked: bar.dispatch('hl.dsp.focus({ workspace = "' + parent.wsId + '" })')
          }
        }
      }
    }

    // ---- center: clock (opens the calendar)
    BarButton {
      anchors.centerIn: parent
      panel: "calendar"
      Text {
        id: clock
        color: Theme.fg
        font { family: Theme.font; pixelSize: bar.fs }
        text: Qt.formatDateTime(new Date(), "ddd d MMM  HH:mm")
        Timer {
          interval: 1000; running: true; repeat: true
          onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd d MMM  HH:mm")
        }
      }
    }

    // ---- right: tray, media, stats, power, bluetooth, network, volume
    Row {
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      spacing: 4

      // System tray (app indicators: Steam, screen sharing, ...) sits leftmost,
      // before the system indicators.
      Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: 6
        Repeater {
          model: SystemTray.items
          delegate: Image {
            required property var modelData
            source: modelData.icon
            width: Theme.s(18); height: Theme.s(18)
            sourceSize: Qt.size(Theme.s(18), Theme.s(18))
            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) modelData.activate()
                else if (modelData.hasMenu) modelData.display(bar, mapToItem(null, mouse.x, mouse.y).x, bar.height)
              }
            }
          }
        }
      }

      // Now playing (first MPRIS player): click to play/pause
      BarButton {
        readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
        visible: player !== null && player.trackTitle !== ""
        onClicked: m => { if (player) player.togglePlaying() }
        Text {
          text: parent.parent.player ? Theme.icon(0xF0386) + " " + parent.parent.player.trackTitle : ""
          color: Theme.fgDim
          elide: Text.ElideRight
          width: Math.min(implicitWidth, 320)
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }

      BarButton {
        panel: "cpu"
        Text {
          text: Theme.icon(0xF0EE0) + " " + bar.cpuPct + "%"
          color: bar.cpuPct > 85 ? Theme.urgent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }
      BarButton {
        panel: "memory"
        Text {
          text: Theme.icon(0xF035B) + " " + bar.memPct + "%"
          color: bar.memPct > 90 ? Theme.urgent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }

      // Battery: only shown when there is one (or a peripheral with one)
      BarButton {
        visible: Battery.shown
        panel: "battery"
        BatteryIcon {
          anchors.verticalCenter: parent.verticalCenter
          unit: 1.1 * Theme.uiScale
          fraction: Battery.barPercent / 100
          charging: Battery.barCharging
          color: Battery.low ? Theme.urgent : Battery.barCharging ? Theme.accent2 : Theme.fg
        }
        Text {
          text: Battery.barPercent + "%"
          color: Battery.low ? Theme.urgent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }

      // Notifications: click for history, right-click toggles do-not-disturb
      BarButton {
        panel: "notifications"
        onClicked: m => { if (m.button === Qt.RightButton) NotificationHistory.setDnd(!NotificationHistory.dnd) }
        Text {
          text: Theme.icon(NotificationHistory.dnd ? 0xF009B : 0xF009C)
          color: NotificationHistory.dnd ? Theme.fgDim : NotificationHistory.unread > 0 ? Theme.accent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs + 1 }
        }
        Text {
          visible: NotificationHistory.unread > 0
          text: NotificationHistory.unread
          color: Theme.accent
          font { family: Theme.font; pixelSize: bar.fs; bold: true }
        }
      }

      // Power profile
      BarButton {
        panel: "power"
        Text {
          text: Theme.icon(bar.profile === "performance" ? 0xF04C5 : bar.profile === "power-saver" ? 0xF032A : 0xF05D1)
          color: bar.profile === "performance" ? Theme.accent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs + 1 }
        }
      }

      // Bluetooth
      BarButton {
        panel: "bluetooth"
        Text {
          readonly property var ad: Bluetooth.defaultAdapter
          readonly property bool on: ad !== null && ad.enabled
          text: Theme.icon(!on ? 0xF00B2 : bar.btConnected > 0 ? 0xF00B1 : 0xF00AF)
          color: !on ? Theme.fgDim : bar.btConnected > 0 ? Theme.accent : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs + 1 }
        }
      }

      // Network
      BarButton {
        panel: "network"
        Text {
          text: bar.netLabel
          color: Theme.fg
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }

      // Volume: click for the audio panel, scroll to change, right-click to mute
      BarButton {
        panel: "audio"
        onClicked: m => { if (m.button === Qt.RightButton && bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted }
        onWheel: w => {
          if (!bar.sink || !bar.sink.audio) return
          var step = w.angleDelta.y > 0 ? 0.05 : -0.05
          bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + step))
        }
        Text {
          text: (bar.muted ? Theme.icon(0xF075F) : Theme.icon(0xF057E)) + " " + Math.round(bar.volume * 100) + "%"
          color: bar.muted ? Theme.fgDim : Theme.fg
          font { family: Theme.font; pixelSize: bar.fs }
        }
      }
    }
  }
}
