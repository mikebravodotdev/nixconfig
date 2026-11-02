import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.common

// Small on-screen display that appears when the default sink's volume or mute changes.
Item {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: [root.sink] }

  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted:  sink && sink.audio ? sink.audio.muted : false

  property bool ready: false
  Timer { interval: 1500; running: true; onTriggered: root.ready = true }  // ignore startup changes

  function show() {
    if (!ready) return
    win.visible = true
    hide.restart()
  }
  onVolumeChanged: show()
  onMutedChanged: show()

  Timer { id: hide; interval: 1200; onTriggered: win.visible = false }

  PanelWindow {
    id: win
    visible: false
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins { bottom: 80 }
    implicitWidth: Theme.s(320)
    implicitHeight: Theme.s(48)
    color: "transparent"
    mask: Region {}   // click-through

    Rectangle {
      anchors.fill: parent
      color: Theme.bg
      border { width: 2; color: Theme.border }

      Text {
        id: label
        anchors { left: parent.left; leftMargin: Theme.s(14); verticalCenter: parent.verticalCenter }
        text: root.muted ? Theme.icon(0xF075F) : Theme.icon(0xF057E)
        color: root.muted ? Theme.fgDim : Theme.fg
        font { family: Theme.font; pixelSize: Theme.s(18) }
      }
      Rectangle {
        anchors { left: label.right; leftMargin: Theme.s(12); right: pct.left; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
        height: Theme.s(6)
        color: Theme.bgAlt
        Rectangle {
          width: parent.width * Math.min(1, root.volume)
          height: parent.height
          color: root.muted ? Theme.fgDim : Theme.accent
        }
      }
      Text {
        id: pct
        anchors { right: parent.right; rightMargin: Theme.s(14); verticalCenter: parent.verticalCenter }
        text: Math.round(root.volume * 100) + "%"
        color: Theme.fg
        font { family: Theme.font; pixelSize: Theme.fontSize }
      }
    }
  }
}
