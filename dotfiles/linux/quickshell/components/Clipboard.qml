import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

// Clipboard history panel over cliphist: searchable list on the left, full
// preview (text or image) on the right.
//   Enter / Alt+1..9  copy that entry      Ctrl+D        delete it
//   Up/Down, Ctrl+J/K/N/P  move            Ctrl+Shift+D  clear everything (asks twice)
//   Esc  close
// Paste afterwards with Super+V (or Ctrl+V).
Scope {
  id: root

  property bool open: false
  function toggle() { open = !open }
  function show()   { open = true }
  function hide()   { open = false }

  readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/clipboard"
  readonly property int maxEntries: 300

  // ------------------------------------------------------------ history
  // entries: [{ id, text, isImage, info }], newest first
  property var entries: []

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        var out = []
        var lines = text.split("\n")
        for (var i = 0; i < lines.length && out.length < root.maxEntries; i++) {
          var line = lines[i]
          var tab = line.indexOf("\t")
          if (tab < 1) continue
          var body = line.slice(tab + 1)
          var img = /^\[\[ binary data (.+?) (png|jpe?g|bmp|gif|webp|tiff?)\s*(\d+x\d+)? \]\]$/i.exec(body)
          out.push({
            id: line.slice(0, tab),
            text: img ? "" : body,
            isImage: img !== null,
            info: img ? (img[3] ? img[3] + " " : "") + img[2].toUpperCase() + " · " + img[1] : body.length + " characters"
          })
        }
        root.entries = out
      }
    }
  }
  function refresh() { listProc.running = true }

  Process { id: maintenance }
  function run(argv) { Quickshell.execDetached(argv) }

  function copy(entry) {
    run(["sh", "-c", 'cliphist decode "$1" | wl-copy', "_", entry.id])
  }
  function remove(entry) {
    run(["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "_", entry.id])
    refreshTimer.restart()
  }
  function wipe() {
    run(["cliphist", "wipe"])
    refreshTimer.restart()
  }
  Timer { id: refreshTimer; interval: 150; onTriggered: root.refresh() }

  function filtered(q) {
    q = q.trim().toLowerCase()
    if (q === "") return entries
    var out = []
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i]
      if (e.isImage ? "image".indexOf(q) >= 0 : e.text.toLowerCase().indexOf(q) >= 0) out.push(e)
    }
    return out
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

    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property string confirming: ""     // "wipe" while waiting for a second Ctrl+Shift+D
    readonly property var current: list.model && list.model.length > 0 ? list.model[list.currentIndex] : null

    onVisibleChanged: if (visible) {
      root.refresh()
      input.text = ""
      list.currentIndex = 0
      confirming = ""
      input.forceActiveFocus()
    }

    // Load the full content of the selected entry for the preview pane.
    property string previewText: ""
    property string previewImage: ""
    property string previewId: ""
    onCurrentChanged: previewTimer.restart()
    Timer {
      id: previewTimer
      interval: 70
      onTriggered: {
        var c = win.current
        if (!c) { win.previewId = ""; win.previewText = ""; win.previewImage = ""; return }
        win.previewId = c.id
        if (c.isImage) {
          win.previewText = ""
          imageProc.command = ["sh", "-c", 'mkdir -p "$2" && cliphist decode "$1" > "$2/$1.img" && echo "$2/$1.img"', "_", c.id, root.cacheDir]
          imageProc.running = true
        } else {
          win.previewImage = ""
          textProc.command = ["cliphist", "decode", c.id]
          textProc.running = true
        }
      }
    }
    Process {
      id: textProc
      stdout: StdioCollector {
        onStreamFinished: if (win.current && win.previewId === win.current.id) win.previewText = text
      }
    }
    Process {
      id: imageProc
      stdout: StdioCollector {
        onStreamFinished: {
          var p = text.trim()
          if (p !== "" && win.current && win.previewId === win.current.id) win.previewImage = "file://" + p
        }
      }
    }

    function activate(index) {
      var e = list.model[index]
      if (!e) return
      root.copy(e)
      root.hide()
    }

    MouseArea { anchors.fill: parent; onClicked: root.hide() }

    Rectangle {
      id: card
      width: Theme.s(1000)
      height: column.implicitHeight
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(parent.height * 0.18)
      radius: Theme.launcherRadius
      color: Theme.card
      border { width: 1; color: Theme.tint(0.2) }
      clip: true

      Column {
        id: column
        width: parent.width

        // ---- search field
        Item {
          width: parent.width
          height: Theme.s(68)

          TextInput {
            id: input
            anchors { left: parent.left; leftMargin: Theme.s(24); right: counter.left; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
            color: Theme.fg
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            font { family: Theme.uiFont; pixelSize: Theme.s(28) }
            clip: true

            Text {
              visible: input.text === ""
              text: "Clipboard history…"
              color: Theme.tint(0.4)
              font: input.font
            }

            onTextChanged: { list.currentIndex = 0; win.confirming = "" }

            Keys.onPressed: event => {
              var ctrl = event.modifiers & Qt.ControlModifier
              var shift = event.modifiers & Qt.ShiftModifier
              var alt = event.modifiers & Qt.AltModifier
              if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true }
              else if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) { win.activate(event.key - Qt.Key_1); event.accepted = true }
              else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); win.confirming = ""; event.accepted = true
              } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                list.currentIndex = Math.max(0, list.currentIndex - 1); win.confirming = ""; event.accepted = true
              } else if (event.key === Qt.Key_PageDown) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8); event.accepted = true }
              else if (event.key === Qt.Key_PageUp)     { list.currentIndex = Math.max(0, list.currentIndex - 8); event.accepted = true }
              else if (ctrl && event.key === Qt.Key_D) {
                if (shift) {
                  if (win.confirming === "wipe") { root.wipe(); win.confirming = ""; list.currentIndex = 0 }
                  else win.confirming = "wipe"
                } else if (win.current) {
                  root.remove(win.current)
                  win.confirming = ""
                }
                event.accepted = true
              }
            }
            Keys.onReturnPressed: win.activate(list.currentIndex)
            Keys.onEnterPressed: win.activate(list.currentIndex)
          }

          Text {
            id: counter
            anchors { right: parent.right; rightMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            text: root.entries.length > 0 ? list.count + " of " + root.entries.length : ""
            color: Theme.tint(0.4)
            font { family: Theme.uiFont; pixelSize: Theme.fontSize - 1 }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13) }

        // ---- body: list | preview
        Row {
          width: parent.width
          height: 9 * Theme.s(52) + Theme.s(8)

          ListView {
            id: list
            width: Theme.s(400)
            height: parent.height
            topMargin: Theme.s(4)
            bottomMargin: Theme.s(4)
            clip: true
            currentIndex: 0
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            model: root.filtered(input.text)
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Item {
              id: row
              required property var modelData
              required property int index
              readonly property bool current: ListView.isCurrentItem
              width: list.width
              height: Theme.s(52)

              Rectangle {
                anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) }
                radius: Theme.launcherRadius - 4
                visible: row.current
                color: Theme.accent
              }

              Text {
                id: glyph
                anchors { left: parent.left; leftMargin: Theme.s(20); verticalCenter: parent.verticalCenter }
                text: Theme.icon(row.modelData.isImage ? 0xF02E9 : 0xF0219)   // image : file-document
                color: row.current ? Theme.onAccent : Theme.accent
                font { family: Theme.uiFont; pixelSize: Theme.s(22) }
              }
              Column {
                anchors { left: glyph.right; leftMargin: Theme.s(12); right: hint.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                  width: parent.width
                  text: row.modelData.isImage ? "Image" : row.modelData.text
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  color: row.current ? Theme.onAccent : Theme.fg
                  font { family: Theme.uiFont; pixelSize: Theme.s(15); bold: row.current }
                }
                Text {
                  width: parent.width
                  text: row.modelData.info
                  elide: Text.ElideRight
                  color: row.current ? Theme.onAccentSoft : Theme.fgDim
                  font { family: Theme.uiFont; pixelSize: Theme.s(11) }
                }
              }
              Text {
                id: hint
                anchors { right: parent.right; rightMargin: Theme.s(22); verticalCenter: parent.verticalCenter }
                text: row.index < 9 ? "⌥" + (row.index + 1) : ""
                color: row.current ? Theme.onAccentFaint : Theme.tint(0.4)
                font { family: Theme.uiFont; pixelSize: Theme.fontSize - 1 }
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: if (list.currentIndex !== row.index) list.currentIndex = row.index
                onClicked: win.activate(row.index)
              }
            }

            // empty states
            Text {
              anchors.centerIn: parent
              visible: list.count === 0
              text: root.entries.length === 0 ? "Clipboard is empty" : "No matches"
              color: Theme.fgDim
              font { family: Theme.uiFont; pixelSize: Theme.s(15) }
            }
          }

          Rectangle { width: 1; height: parent.height; color: Theme.tint(0.13) }

          // preview
          Item {
            width: parent.width - list.width - 1
            height: parent.height

            Image {
              anchors { fill: parent; margins: Theme.s(16) }
              visible: win.current && win.current.isImage
              source: visible ? win.previewImage : ""
              fillMode: Image.PreserveAspectFit
              horizontalAlignment: Image.AlignLeft
              verticalAlignment: Image.AlignTop
              asynchronous: true
              cache: false
            }
            Flickable {
              anchors { fill: parent; margins: Theme.s(16) }
              visible: win.current && !win.current.isImage
              clip: true
              contentHeight: previewLabel.implicitHeight
              interactive: contentHeight > height
              Text {
                id: previewLabel
                width: parent.width
                text: win.previewText
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.fg
                font { family: Theme.font; pixelSize: Theme.s(13) }
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13) }

        // ---- footer
        Item {
          width: parent.width
          height: Theme.s(34)
          Text {
            anchors { left: parent.left; leftMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            text: win.confirming === "wipe"
                  ? "Press Ctrl+Shift+D again to clear the whole history"
                  : "↵ copy    ⌃D delete    ⌃⇧D clear all    esc close"
            color: win.confirming === "wipe" ? Theme.urgent : Theme.tint(0.5)
            font { family: Theme.uiFont; pixelSize: Theme.s(12) }
          }
        }
      }
    }
  }
}
