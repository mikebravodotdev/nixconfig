import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

// Keybinding cheat sheet (Super+K), after Omarchy's. Reads
// ~/.local/state/quickshell/binds.json, written by hypr/conf/bindings.lua
// from the very bind() calls that register the keys with Hyprland -- so this
// is always exactly what's bound, never a separate list to keep in sync.
Scope {
  id: root

  property bool open: false
  function toggle() { open = !open }
  function show()   { open = true }
  function hide()   { open = false }

  property var binds: []

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/quickshell/binds.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.binds = JSON.parse(text()) } catch (e) { console.warn("Cheatsheet: bad binds.json:", e) }
    }
  }

  // Raw bind() key token -> display label.
  function keyLabel(tok) {
    const map = {
      "RETURN": "Enter", "SPACE": "Space", "TAB": "Tab", "ESCAPE": "Esc", "ALT": "Alt",
      "LEFT": "←", "RIGHT": "→", "UP": "↑", "DOWN": "↓",
      "grave": "`", "comma": ",", "PRINT": "Print",
      "code:20": "-", "code:21": "=",
      "mouse:272": "Click", "mouse:273": "Right click",
      "mouse_down": "Scroll down", "mouse_up": "Scroll up",
    }
    if (map[tok] !== undefined) return map[tok]
    if (tok.indexOf("XF86") === 0) return tok.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2")
    return tok.length <= 1 ? tok : tok.charAt(0) + tok.slice(1).toLowerCase()
  }

  function keysLabel(raw) {
    return raw.split("+").map(function(p) { return root.keyLabel(p.trim()) }).join(" + ")
  }

  // Bound entries, grouped by category in first-seen order.
  function groups() {
    var order = [], byCat = {}
    for (var i = 0; i < binds.length; i++) {
      var b = binds[i]
      if (!byCat[b.category]) { byCat[b.category] = []; order.push(b.category) }
      byCat[b.category].push(b)
    }
    return order.map(function(name) { return { name: name, items: byCat[name] } })
  }

  // Greedily balance category blocks across `n` columns by row count, so no
  // one column ends up far taller than the others.
  function columns(n) {
    var gs = groups()
    var heights = []
    var cols = []
    for (var i = 0; i < n; i++) { heights.push(0); cols.push([]) }
    for (var j = 0; j < gs.length; j++) {
      var g = gs[j]
      var min = 0
      for (var c = 1; c < n; c++) if (heights[c] < heights[min]) min = c
      cols[min].push(g)
      heights[min] += g.items.length + 1.5
    }
    return cols
  }

  PanelWindow {
    id: win
    visible: root.open

    screen: {
      var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    WlrLayershell.namespace: "qs-cheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property int cols: 3
    // Shrink-to-fit: the layout is designed at full size for a big ultrawide;
    // on smaller (logical) screens everything scales down uniformly so all
    // three columns fit, whatever the monitor.
    readonly property real naturalWidth: Theme.s(cols * 640 + 28 * (cols - 1) + 48)
    readonly property real fit: Math.min(1, (width - Theme.s(40)) / naturalWidth)
    function z(n) { return Math.round(Theme.s(n) * fit) }
    readonly property int colWidth: z(640)
    readonly property int keysWidth: z(280)

    onVisibleChanged: if (visible) keys.forceActiveFocus()

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
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_K) { root.hide(); event.accepted = true }
      }

      Rectangle {
        id: card
        anchors.centerIn: parent
        width: win.cols * win.colWidth + win.z(28) * (win.cols - 1) + win.z(48)
        height: Math.min(parent.height - win.z(80), body.implicitHeight + heading.height + win.z(70))
        radius: Theme.launcherRadius
        color: Theme.card
        border { width: 1; color: Theme.tint(0.2) }
        clip: true

        Text {
          id: heading
          anchors { top: parent.top; topMargin: win.z(20); horizontalCenter: parent.horizontalCenter }
          text: "Keybindings"
          color: Theme.fg
          font { family: Theme.uiFont; pixelSize: win.z(30); bold: true }
        }

        Flickable {
          anchors { top: heading.bottom; topMargin: win.z(14); left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: win.z(34) }
          anchors.margins: win.z(24)
          contentWidth: width
          contentHeight: body.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Row {
            id: body
            spacing: win.z(28)

            Repeater {
              model: root.columns(win.cols)
              delegate: Column {
                id: col
                required property var modelData
                width: win.colWidth
                spacing: win.z(24)

                Repeater {
                  model: col.modelData
                  delegate: Column {
                    required property var modelData
                    width: col.width
                    spacing: win.z(8)

                    Text {
                      text: modelData.name
                      color: Theme.accent
                      font { family: Theme.uiFont; pixelSize: win.z(20); bold: true; capitalization: Font.AllUppercase }
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.tint(0.15) }

                    Repeater {
                      model: modelData.items
                      delegate: Row {
                        required property var modelData
                        width: col.width
                        spacing: win.z(14)

                        Text {
                          width: win.keysWidth
                          text: root.keysLabel(modelData.keys)
                          color: Theme.fgBright
                          font { family: Theme.font; pixelSize: win.z(24); bold: true }
                          elide: Text.ElideRight
                        }
                        Text {
                          width: col.width - win.keysWidth - win.z(14)
                          text: modelData.description
                          color: Theme.fgDim
                          font { family: Theme.uiFont; pixelSize: win.z(24) }
                          elide: Text.ElideRight
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: root.binds.length === 0
            text: "No keybindings found"
            color: Theme.fgDim
            font { family: Theme.uiFont; pixelSize: win.z(15) }
          }
        }

        Text {
          anchors { bottom: parent.bottom; bottomMargin: win.z(10); horizontalCenter: parent.horizontalCenter }
          text: "esc / Super+K close"
          color: Theme.tint(0.5)
          font { family: Theme.uiFont; pixelSize: win.z(11) }
        }
      }
    }
  }
}
