import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

// System menu: Lock, Sleep, Log Out, Restart, Shut Down.
//   Left/Right or Tab move, Enter (or Space) runs, Esc closes.
//   Single-letter hotkeys: L S O R D.
//   Log Out, Restart and Shut Down turn red and need a second press.
Scope {
  id: root

  property bool open: false
  function toggle() { open = !open }
  function show()   { open = true }
  function hide()   { open = false }

  readonly property var tiles: SystemActions.list.filter(function(a) { return a.menu })

  PanelWindow {
    id: win
    visible: root.open

    screen: {
      var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    WlrLayershell.namespace: "qs-system-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int selected: 0
    property string confirming: ""   // id waiting for a second press

    onVisibleChanged: if (visible) {
      selected = 0
      confirming = ""
      keys.forceActiveFocus()
    }

    function activate(index) {
      var a = root.tiles[index]
      if (!a) return
      if (a.confirm && confirming !== a.id) { selected = index; confirming = a.id; return }
      Quickshell.execDetached(a.cmd)
      root.hide()
    }

    // Dimmed backdrop; click anywhere outside the card to close.
    Rectangle {
      anchors.fill: parent
      color: Theme.scrim
      MouseArea { anchors.fill: parent; onClicked: root.hide() }
    }

    Item {
      id: keys
      anchors.fill: parent
      focus: true

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true; return }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
          win.selected = (win.selected + root.tiles.length - 1) % root.tiles.length; win.confirming = ""; event.accepted = true; return
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
          win.selected = (win.selected + 1) % root.tiles.length; win.confirming = ""; event.accepted = true; return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          win.activate(win.selected); event.accepted = true; return
        }
        var typed = (event.text || "").toUpperCase()
        for (var i = 0; i < root.tiles.length; i++) {
          if (typed !== "" && root.tiles[i].key === typed) { win.activate(i); event.accepted = true; return }
        }
      }

      Rectangle {
        id: card
        anchors.centerIn: parent
        width: row.implicitWidth + Theme.s(48)
        height: row.implicitHeight + Theme.s(48) + footer.height
        radius: Theme.launcherRadius
        color: Theme.card
        border { width: 1; color: Theme.tint(0.2) }

        Row {
          id: row
          x: Theme.s(24); y: Theme.s(24)
          spacing: Theme.s(12)

          Repeater {
            model: root.tiles
            delegate: Item {
              id: tile
              required property var modelData
              required property int index
              readonly property bool current: win.selected === index
              readonly property bool asking: win.confirming === modelData.id
              width: Theme.s(150); height: Theme.s(160)

              Rectangle {
                anchors.fill: parent
                radius: Theme.launcherRadius - 2
                color: tile.asking ? Theme.urgent : (tile.current ? Theme.accent : Theme.bgAlt)
              }

              Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.s(24) }
                text: Theme.icon(tile.modelData.glyph)
                color: tile.current ? Theme.onAccent : Theme.fg
                font { family: Theme.uiFont; pixelSize: Theme.s(52) }
              }
              Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.s(98) }
                text: tile.asking ? "Press again" : tile.modelData.title
                color: tile.current ? Theme.onAccent : Theme.fg
                font { family: Theme.uiFont; pixelSize: Theme.s(16); bold: tile.current }
              }
              // hotkey cap
              Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.s(14) }
                width: Theme.s(24); height: Theme.s(22)
                radius: Theme.s(4)
                color: "transparent"
                border { width: 1; color: tile.current ? Theme.onAccentFaint : Theme.tint(0.33) }
                Text {
                  anchors.centerIn: parent
                  text: tile.modelData.key
                  color: tile.current ? Theme.onAccentSoft : Theme.tint(0.6)
                  font { family: Theme.uiFont; pixelSize: Theme.s(12); bold: true }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: if (win.selected !== tile.index) { win.selected = tile.index; win.confirming = "" }
                onClicked: win.activate(tile.index)
              }
            }
          }
        }

        Text {
          id: footer
          width: parent.width
          height: Theme.s(34)
          anchors.bottom: parent.bottom
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: {
            var a = root.tiles[win.selected]
            return win.confirming !== "" ? "Press again to confirm, or Esc to cancel"
                                          : (a ? a.subtitle : "") + "    ·    ←→ select   ↵ run   esc close"
          }
          color: win.confirming !== "" ? Theme.urgent : Theme.tint(0.5)
          font { family: Theme.uiFont; pixelSize: Theme.s(12) }
        }
      }
    }
  }
}
