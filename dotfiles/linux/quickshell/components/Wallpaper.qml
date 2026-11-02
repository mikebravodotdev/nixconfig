import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Wallpaper on the background layer of one screen, crossfading when it changes.
// The image path comes from the theme state (Theme.wallpaper).
PanelWindow {
  id: win

  WlrLayershell.namespace: "qs-wallpaper"
  WlrLayershell.layer: WlrLayer.Background
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  color: Theme.bg

  readonly property string target: Theme.wallpaper === "" ? "" : "file://" + Theme.wallpaper

  // Two stacked images: `back` shows the old picture while `front` fades in over it.
  Image {
    id: back
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
  }
  Image {
    id: front
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    opacity: 0

    onStatusChanged: if (status === Image.Ready && source.toString() === win.target) fade.restart()
  }

  SequentialAnimation {
    id: fade
    NumberAnimation { target: front; property: "opacity"; from: 0; to: 1; duration: 450; easing.type: Easing.OutQuad }
    ScriptAction {
      script: {
        back.source = front.source      // settle: the old picture becomes the new one
        front.opacity = 0
      }
    }
  }

  onTargetChanged: {
    if (target === "") return
    if (back.source.toString() === "") { back.source = target; return }   // first image: no fade
    fade.stop()
    front.opacity = 0
    front.source = target
  }
  Component.onCompleted: if (target !== "") back.source = target
}
