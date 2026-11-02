import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

// Theme and wallpaper switcher: a grid of previews.
//   Tab           switch between Themes and Backgrounds
//   Arrows        move around the grid     type  filter by name
//   Enter / click apply                    Esc   close
// `theme-apply` does the work; the shell recolors itself when the state file changes.
Scope {
  id: root

  property bool open: false
  property string mode: "theme"        // "theme" | "background"
  function toggle(m) { if (open && mode === m) open = false; else { mode = m; open = true } }
  function show(m)   { mode = m; open = true }
  function hide()    { open = false }

  readonly property string applyBin: Quickshell.env("HOME") + "/.local/bin/theme-apply"

  // ------------------------------------------------------------ data
  property var data: ({ current: "", background: "", themes: [] })

  Process {
    id: listProc
    command: [root.applyBin, "--list"]
    stdout: StdioCollector {
      onStreamFinished: { try { root.data = JSON.parse(text) } catch (e) { console.warn("Appearance: bad list:", e) } }
    }
  }
  function refresh() { listProc.running = true }

  // Items for the current mode, filtered by the search text.
  function items(q) {
    q = q.trim().toLowerCase()
    var out = []
    if (mode === "theme") {
      for (var i = 0; i < data.themes.length; i++) {
        var t = data.themes[i]
        if (q === "" || t.title.toLowerCase().indexOf(q) >= 0)
          out.push({ key: t.name, label: t.title, image: t.preview, accent: t.accent, bg: t.background,
                     current: t.name === Theme.name })
      }
    } else {
      var cur = null
      for (var j = 0; j < data.themes.length; j++) if (data.themes[j].name === Theme.name) cur = data.themes[j]
      var list = cur ? cur.backgrounds : []
      for (var k = 0; k < list.length; k++) {
        var file = list[k]
        var base = file.split("/").pop().replace(/\.[^.]+$/, "").replace(/^\d+[-_]/, "").replace(/[-_]/g, " ")
        if (q === "" || base.toLowerCase().indexOf(q) >= 0)
          out.push({ key: file, label: base, image: file, accent: "", bg: "", current: file === Theme.wallpaper })
      }
    }
    return out
  }

  function apply(item) {
    if (!item) return
    if (mode === "theme") Quickshell.execDetached([applyBin, item.key])
    else Quickshell.execDetached([applyBin, "--background", item.key])
  }

  // ------------------------------------------------------------ window
  PanelWindow {
    id: win
    visible: root.open

    screen: {
      var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    WlrLayershell.namespace: "qs-appearance"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property int cols: 4
    readonly property int cellW: Theme.s(270)
    readonly property int cellH: Theme.s(190)

    onVisibleChanged: if (visible) {
      root.refresh()
      input.text = ""
      grid.currentIndex = 0
      input.forceActiveFocus()
      posTimer.restart()
    }
    // Land on the item that is currently applied once the list is built.
    Timer {
      id: posTimer
      interval: 120
      onTriggered: {
        var m = grid.model
        for (var i = 0; i < m.length; i++) if (m[i].current) { grid.currentIndex = i; return }
      }
    }
    Connections { target: root; function onModeChanged() { input.text = ""; grid.currentIndex = 0; posTimer.restart() } }
    Connections { target: root; function onDataChanged() { posTimer.restart() } }

    MouseArea { anchors.fill: parent; onClicked: root.hide() }

    Rectangle {
      id: card
      width: win.cols * win.cellW + Theme.s(40)
      height: column.implicitHeight
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(parent.height * 0.14)
      radius: Theme.launcherRadius
      color: Theme.card
      border { width: 1; color: Theme.tint(0.2) }
      clip: true

      Column {
        id: column
        width: parent.width

        // ---- search + tabs
        Item {
          width: parent.width
          height: Theme.s(68)

          TextInput {
            id: input
            anchors { left: parent.left; leftMargin: Theme.s(24); right: tabs.left; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
            color: Theme.fg
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            font { family: Theme.uiFont; pixelSize: Theme.s(28) }
            clip: true

            Text {
              visible: input.text === ""
              text: root.mode === "theme" ? "Search themes…" : "Search backgrounds…"
              color: Theme.tint(0.4)
              font: input.font
            }

            onTextChanged: grid.currentIndex = 0

            Keys.onPressed: event => {
              var n = grid.count
              if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true }
              else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.mode = root.mode === "theme" ? "background" : "theme"; event.accepted = true
              } else if (event.key === Qt.Key_Right) { grid.currentIndex = Math.min(n - 1, grid.currentIndex + 1); event.accepted = true }
              else if (event.key === Qt.Key_Left)  { grid.currentIndex = Math.max(0, grid.currentIndex - 1); event.accepted = true }
              else if (event.key === Qt.Key_Down)  { grid.currentIndex = Math.min(n - 1, grid.currentIndex + win.cols); event.accepted = true }
              else if (event.key === Qt.Key_Up)    { grid.currentIndex = Math.max(0, grid.currentIndex - win.cols); event.accepted = true }
            }
            Keys.onReturnPressed: { root.apply(grid.model[grid.currentIndex]); root.hide() }
            Keys.onEnterPressed:  { root.apply(grid.model[grid.currentIndex]); root.hide() }
          }

          // Tabs
          Row {
            id: tabs
            anchors { right: parent.right; rightMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            spacing: Theme.s(6)
            Repeater {
              model: [{ id: "theme", label: "Themes" }, { id: "background", label: "Backgrounds" }]
              delegate: Rectangle {
                required property var modelData
                readonly property bool on: root.mode === modelData.id
                width: tabLabel.implicitWidth + Theme.s(24); height: Theme.s(30)
                radius: Theme.s(8)
                color: on ? Theme.accent : "transparent"
                border { width: 1; color: on ? Theme.accent : Theme.tint(0.2) }
                Text {
                  id: tabLabel
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: parent.on ? Theme.onAccent : Theme.fgDim
                  font { family: Theme.uiFont; pixelSize: Theme.s(13); bold: parent.on }
                }
                MouseArea { anchors.fill: parent; onClicked: root.mode = parent.modelData.id }
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13) }

        // ---- grid
        GridView {
          id: grid
          x: Theme.s(20)
          width: win.cols * win.cellW
          height: Math.min(3, Math.max(1, Math.ceil(count / win.cols))) * win.cellH + Theme.s(20)
          topMargin: Theme.s(10)
          bottomMargin: Theme.s(10)
          cellWidth: win.cellW
          cellHeight: win.cellH
          clip: true
          currentIndex: 0
          highlightMoveDuration: 0
          boundsBehavior: Flickable.StopAtBounds
          model: root.items(input.text)
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

          delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool sel: GridView.isCurrentItem
            width: win.cellW; height: win.cellH

            Rectangle {   // selection plate
              anchors { fill: parent; margins: Theme.s(4) }
              radius: Theme.launcherRadius - 2
              color: cell.sel ? Theme.accent : "transparent"
            }

            Rectangle {   // thumbnail frame
              id: frame
              anchors { top: parent.top; topMargin: Theme.s(10); horizontalCenter: parent.horizontalCenter }
              width: win.cellW - Theme.s(28); height: Theme.s(138)
              radius: Theme.s(6)
              color: cell.modelData.bg !== "" ? cell.modelData.bg : Theme.bgAlt
              clip: true

              Image {
                anchors.fill: parent
                source: cell.modelData.image !== "" ? "file://" + cell.modelData.image : ""
                sourceSize: Qt.size(480, 270)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
              }
              // palette swatches for themes
              Row {
                visible: cell.modelData.accent !== ""
                anchors { right: parent.right; bottom: parent.bottom; margins: Theme.s(6) }
                spacing: Theme.s(3)
                Rectangle { width: Theme.s(14); height: Theme.s(14); radius: Theme.s(7); color: cell.modelData.accent; border { width: 1; color: "#80000000" } }
                Rectangle { width: Theme.s(14); height: Theme.s(14); radius: Theme.s(7); color: cell.modelData.bg;     border { width: 1; color: "#80ffffff" } }
              }
              // "in use" badge
              Rectangle {
                visible: cell.modelData.current
                anchors { left: parent.left; top: parent.top; margins: Theme.s(6) }
                width: badge.implicitWidth + Theme.s(14); height: Theme.s(20); radius: Theme.s(10)
                color: Theme.accent
                Text {
                  id: badge
                  anchors.centerIn: parent
                  text: "In use"
                  color: Theme.onAccent
                  font { family: Theme.uiFont; pixelSize: Theme.s(11); bold: true }
                }
              }
            }

            Text {
              anchors { left: frame.left; right: frame.right; top: frame.bottom; topMargin: Theme.s(6) }
              text: cell.modelData.label
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              color: cell.sel ? Theme.onAccent : Theme.fg
              font { family: Theme.uiFont; pixelSize: Theme.s(14); bold: cell.sel; capitalization: Font.Capitalize }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onPositionChanged: if (grid.currentIndex !== cell.index) grid.currentIndex = cell.index
              onClicked: { root.apply(cell.modelData); root.hide() }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: grid.count === 0
            text: root.mode === "background" ? "No wallpapers for this theme" : "No matches"
            color: Theme.fgDim
            font { family: Theme.uiFont; pixelSize: Theme.s(15) }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13) }

        Item {
          width: parent.width
          height: Theme.s(34)
          Text {
            anchors { left: parent.left; leftMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            text: "↵ apply    ⇥ " + (root.mode === "theme" ? "backgrounds" : "themes") + "    ←↑↓→ move    esc close"
            color: Theme.tint(0.5)
            font { family: Theme.uiFont; pixelSize: Theme.s(12) }
          }
          Text {
            anchors { right: parent.right; rightMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            text: grid.count + (grid.count === 1 ? " item" : " items")
            color: Theme.tint(0.5)
            font { family: Theme.uiFont; pixelSize: Theme.s(12) }
          }
        }
      }
    }
  }
}
