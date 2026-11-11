import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

// Alfred-style launcher.
//   - Just the search bar until you type.
//   - Results: apps (ranked by match + how often you launch them), inline
//     calculator, system commands, web-search fallbacks when nothing matches.
//   - Enter runs, Alt+1..9 runs that row, Tab autocompletes, Esc closes,
//     Up/Down or Ctrl+J/K/N/P move. ">cmd" runs a shell command.
//   - Reboot, shut down and log out ask for a second Enter.
Scope {
  id: root

  property bool open: false
  property string pendingQuery: ""
  function toggle() { open = !open }
  function show()   { open = true }
  function hide()   { open = false }
  function query(text) { pendingQuery = text; open = true }

  readonly property string terminal: "ghostty"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"

  // ------------------------------------------------------------ usage counts
  property var usage: ({})
  Process { command: ["mkdir", "-p", root.stateDir]; running: true }
  FileView {
    id: usageFile
    path: root.stateDir + "/launcher-usage.json"
    printErrors: false
    onLoaded: { try { root.usage = JSON.parse(text()) } catch (e) { root.usage = ({}) } }
  }
  function bump(id) {
    if (!id) return
    var u = Object.assign({}, usage)
    u[id] = (u[id] || 0) + 1
    usage = u
    usageFile.setText(JSON.stringify(u))
  }

  // ------------------------------------------------------------ providers
  // A result is { id, title, subtitle, icon | glyph, confirm, run() }.

  function matchScore(name, extra, q) {
    name = name.toLowerCase()
    if (name === q) return 1000
    if (name.startsWith(q)) return 800
    if (name.indexOf(" " + q) >= 0) return 600
    if (name.indexOf(q) >= 0) return 400
    if (extra && extra.toLowerCase().indexOf(q) >= 0) return 150
    var i = 0
    for (var c = 0; c < name.length && i < q.length; c++) if (name[c] === q[i]) i++
    return i === q.length ? 50 : -1
  }

  function appResults(q) {
    var apps = DesktopEntries.applications.values
    var out = []
    for (var i = 0; i < apps.length; i++) {
      var e = apps[i]
      if (e.noDisplay) continue
      var s = matchScore(e.name || "", (e.genericName || "") + " " + (e.keywords ? e.keywords.join(" ") : "") + " " + (e.comment || ""), q)
      if (s < 0) continue
      out.push({
        score: s + Math.min(80, (usage[e.id] || 0) * 8),
        r: {
          id: e.id, title: e.name,
          subtitle: e.genericName || e.comment || "Application",
          icon: e.icon,
          run: (function(entry) { return function() {
            if (entry.runInTerminal) Quickshell.execDetached([terminal, "-e"].concat(entry.command))
            else entry.execute()
          } })(e)
        }
      })
    }
    out.sort(function(a, b) { return b.score - a.score || a.r.title.localeCompare(b.r.title) })
    return out.map(function(x) { return x.r })
  }

  function systemResults(q) {
    var out = []
    for (var i = 0; i < SystemActions.list.length; i++) {
      var c = SystemActions.list[i]
      if (matchScore(c.title, c.subtitle, q) < 0) continue
      out.push({
        id: c.id, title: c.title, subtitle: c.subtitle, glyph: c.glyph, confirm: !!c.confirm,
        run: (function(cmd) { return function() { Quickshell.execDetached(cmd) } })(c.cmd)
      })
    }
    return out
  }

  // Arithmetic only: digits, operators, parentheses, decimal point, ^ for power.
  function calcResult(text) {
    var t = text.trim()
    if (t === "" || !/^[0-9+\-*\/().%^,\s]+$/.test(t) || !/[+\-*\/%^]/.test(t.replace(/^[-+]/, ""))) return null
    try {
      var v = Function('"use strict"; return (' + t.replace(/\^/g, "**").replace(/,/g, "") + ")")()
      if (typeof v !== "number" || !isFinite(v)) return null
      var shown = String(Math.round(v * 1e10) / 1e10)
      return {
        id: "", title: "= " + shown, subtitle: "Enter copies the result to the clipboard", glyph: 0xF00EC,
        run: function() { Quickshell.execDetached(["wl-copy", shown]) }
      }
    } catch (e) { return null }
  }

  function webResults(text) {
    var q = encodeURIComponent(text.trim())
    return [
      { id: "", title: "Search the web for “" + text.trim() + "”", subtitle: "DuckDuckGo", glyph: 0xF059F,
        run: function() { Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + q]) } },
      { id: "", title: "Search Wikipedia for “" + text.trim() + "”", subtitle: "wikipedia.org", glyph: 0xF059F,
        run: function() { Quickshell.execDetached(["xdg-open", "https://en.wikipedia.org/w/index.php?search=" + q]) } }
    ]
  }

  function search(text) {
    var raw = text.trim()
    if (raw === "") return []
    if (raw.startsWith(">")) {
      var cmd = raw.slice(1).trim()
      return cmd === "" ? [] : [{
        id: "", title: "Run  " + cmd, subtitle: "Shell command", glyph: 0xF0489,
        run: function() { Quickshell.execDetached(["sh", "-c", cmd]) }
      }]
    }
    var q = raw.toLowerCase()
    var out = []
    var calc = calcResult(raw)
    if (calc) out.push(calc)
    out = out.concat(appResults(q), systemResults(q))
    if (out.length === 0) out = webResults(raw)
    return out.slice(0, 9)
  }

  // ------------------------------------------------------------ window
  PanelWindow {
    id: win
    visible: root.open

    // Open on the focused monitor.
    screen: {
      var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      for (var i = 0; i < Quickshell.screens.length; i++)
        if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    onVisibleChanged: if (visible) {
      input.text = root.pendingQuery
      root.pendingQuery = ""
      list.currentIndex = 0
      confirming = ""
      input.forceActiveFocus()
    }

    property string confirming: ""   // id of the row waiting for a second Enter

    function activate(index) {
      var item = list.model[index]
      if (!item) return
      if (item.confirm && confirming !== item.id) { confirming = item.id; return }
      root.bump(item.id)
      item.run()
      root.hide()
    }

    // Click outside the card to close.
    MouseArea { anchors.fill: parent; onClicked: root.hide() }

    Rectangle {
      id: card
      width: Theme.s(700)
      height: column.implicitHeight
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(parent.height * 0.2)
      radius: Theme.launcherRadius
      color: Theme.card
      border { width: 1; color: Theme.tint(0.2) }
      clip: true

      Column {
        id: column
        width: parent.width

        // ---- search field: big, borderless
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
              text: "Search apps, calculate, run…"
              color: Theme.tint(0.4)
              font: input.font
            }

            onTextChanged: { list.currentIndex = 0; win.confirming = "" }

            Keys.onPressed: event => {
              var ctrl = event.modifiers & Qt.ControlModifier
              var alt = event.modifiers & Qt.AltModifier
              if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true }
              else if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                win.activate(event.key - Qt.Key_1); event.accepted = true
              } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); win.confirming = ""; event.accepted = true
              } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                list.currentIndex = Math.max(0, list.currentIndex - 1); win.confirming = ""; event.accepted = true
              } else if (event.key === Qt.Key_Tab) {
                // Autocomplete to the selected result's title, like Alfred.
                var item = list.model[list.currentIndex]
                if (item && item.id.indexOf("sys:") !== 0 && item.title.indexOf("=") !== 0 && item.title.indexOf("Search") !== 0) {
                  input.text = item.title
                  input.cursorPosition = input.text.length
                }
                event.accepted = true
              }
            }
            Keys.onReturnPressed: win.activate(list.currentIndex)
            Keys.onEnterPressed: win.activate(list.currentIndex)
          }

          // How many matches, top right of the field
          Text {
            id: counter
            anchors { right: parent.right; rightMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
            text: list.count > 0 ? list.count + (list.count === 1 ? " result" : " results") : ""
            color: Theme.tint(0.4)
            font { family: Theme.uiFont; pixelSize: Theme.fontSize - 1 }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.tint(0.13); visible: list.count > 0 }

        // ---- results
        ListView {
          id: list
          width: parent.width
          readonly property int rowHeight: Theme.s(58)
          height: count * rowHeight + (count > 0 ? Theme.s(8) : 0)
          topMargin: count > 0 ? Theme.s(4) : 0
          bottomMargin: count > 0 ? Theme.s(4) : 0
          visible: count > 0
          interactive: false
          currentIndex: 0
          highlightMoveDuration: 0
          model: root.search(input.text)

          delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            readonly property bool asking: !!modelData.confirm && win.confirming === modelData.id
            width: list.width
            height: list.rowHeight

            Rectangle {   // selected row: accent fill, inset and rounded
              anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(8) }
              radius: Theme.launcherRadius - 4
              visible: row.current
              color: row.asking ? Theme.urgent : Theme.accent
            }

            // icon: a theme icon for apps, a glyph for built-ins
            Item {
              id: iconBox
              anchors { left: parent.left; leftMargin: Theme.s(24); verticalCenter: parent.verticalCenter }
              width: Theme.s(36); height: Theme.s(36)
              Image {
                anchors.fill: parent
                visible: row.modelData.glyph === undefined
                sourceSize: Qt.size(Theme.s(36), Theme.s(36))
                source: row.modelData.glyph === undefined
                        ? Quickshell.iconPath(row.modelData.icon || "", "application-x-executable") : ""
              }
              Text {
                anchors.centerIn: parent
                visible: row.modelData.glyph !== undefined
                text: row.modelData.glyph !== undefined ? Theme.icon(row.modelData.glyph) : ""
                color: row.current ? Theme.onAccent : Theme.accent
                font { family: Theme.uiFont; pixelSize: Theme.s(28) }
              }
            }

            Column {
              anchors { left: iconBox.right; leftMargin: Theme.s(14); right: hint.left; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
              spacing: 1
              Text {
                width: parent.width
                text: row.modelData.title
                elide: Text.ElideRight
                color: row.current ? Theme.onAccent : Theme.fg
                font { family: Theme.uiFont; pixelSize: Theme.s(17); bold: row.current }
              }
              Text {
                width: parent.width
                text: row.asking ? "Press Enter again to confirm" : row.modelData.subtitle
                elide: Text.ElideRight
                color: row.current ? Theme.onAccentSoft : Theme.fgDim
                font { family: Theme.uiFont; pixelSize: Theme.s(12) }
              }
            }

            // quick-select hint
            Text {
              id: hint
              anchors { right: parent.right; rightMargin: Theme.s(28); verticalCenter: parent.verticalCenter }
              text: "⌥" + (row.index + 1)
              color: row.current ? Theme.onAccentFaint : Theme.tint(0.4)
              font { family: Theme.uiFont; pixelSize: Theme.fontSize }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onPositionChanged: if (list.currentIndex !== row.index) { list.currentIndex = row.index; win.confirming = "" }
              onClicked: win.activate(row.index)
            }
          }
        }
      }
    }
  }
}
