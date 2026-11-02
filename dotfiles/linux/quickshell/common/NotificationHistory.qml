pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Every notification the daemon receives, kept after the toast is gone.
// Saved to ~/.local/state/quickshell/notifications.json (plain text, newest first,
// capped and pruned), together with the do-not-disturb switch.
Singleton {
  id: root

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"
  readonly property int maxEntries: 200
  readonly property real maxAgeMs: 14 * 24 * 3600 * 1000

  property var entries: []       // [{ id, app, icon, summary, body, urgency, time, read }]
  property bool dnd: false       // do not disturb: record, but show no toasts
  readonly property int unread: entries.filter(e => !e.read).length

  property bool loaded: false
  property int seq: 0

  // ------------------------------------------------------------ changes
  function add(n) {
    var e = {
      id: Date.now() * 1000 + (seq++ % 1000),
      app: n.appName || "",
      icon: n.appIcon || "",
      summary: n.summary || "",
      body: n.body || "",
      urgency: n.urgency === undefined ? 1 : n.urgency,   // 0 low, 1 normal, 2 critical
      time: Date.now(),
      read: false
    }
    entries = [e].concat(entries).slice(0, maxEntries)
    scheduleSave()
  }
  function remove(id) {
    entries = entries.filter(e => e.id !== id)
    scheduleSave()
  }
  function clear() {
    entries = []
    scheduleSave()
  }
  function markRead() {
    if (unread === 0) return
    entries = entries.map(e => e.read ? e : Object.assign({}, e, { read: true }))
    scheduleSave()
  }
  function setDnd(on) {
    dnd = on
    scheduleSave()
  }

  // ------------------------------------------------------------ persistence
  Process { command: ["mkdir", "-p", root.stateDir]; running: true }

  FileView {
    id: file
    path: root.stateDir + "/notifications.json"
    printErrors: false
    onLoaded: {
      var saved = []
      try {
        var d = JSON.parse(text())
        saved = d.entries || []
        root.dnd = !!d.dnd
      } catch (e) {}
      // Merge with anything that arrived before the file finished loading.
      var seen = {}, merged = []
      var all = root.entries.concat(saved)
      var cutoff = Date.now() - root.maxAgeMs
      for (var i = 0; i < all.length; i++) {
        var e = all[i]
        if (seen[e.id] || e.time < cutoff) continue
        seen[e.id] = true
        merged.push(e)
      }
      merged.sort((a, b) => b.time - a.time)
      root.entries = merged.slice(0, root.maxEntries)
      root.loaded = true
    }
    onLoadFailed: root.loaded = true
  }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: if (root.loaded) file.setText(JSON.stringify({ dnd: root.dnd, entries: root.entries }))
  }
  function scheduleSave() { saveTimer.restart() }
}
