import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components

// Wired status and Wi-Fi: scan, connect, disconnect, radio on/off. Uses nmcli.
Column {
  id: root
  width: Theme.s(400)

  // ---- state
  property bool radioOn: false
  property bool hasWifi: false
  property var wired: ({ conn: "", state: "", ip: "", dev: "" })
  property var networks: []        // [{ ssid, signal, secure, inUse, known }]
  property var known: ({})         // saved connection names
  property string asking: ""       // ssid waiting for a password
  property string busy: ""         // ssid being connected

  // nmcli -t escapes ':' and '\' with a backslash.
  function split(line) {
    var out = [], cur = ""
    for (var i = 0; i < line.length; i++) {
      var c = line[i]
      if (c === "\\" && i + 1 < line.length) cur += line[++i]
      else if (c === ":") { out.push(cur); cur = "" }
      else cur += c
    }
    out.push(cur)
    return out
  }

  Process {
    id: statusProc
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.split("\n"), w = { conn: "", state: "", ip: "", dev: "" }, wifi = false
        for (var i = 0; i < lines.length; i++) {
          var f = root.split(lines[i])
          if (f[1] === "wifi") wifi = true
          if (f[1] === "ethernet" && w.dev === "") w = { conn: f[3], state: f[2], ip: "", dev: f[0] }
        }
        root.hasWifi = wifi
        root.wired = w
        if (w.dev !== "") { ipProc.command = ["nmcli", "-g", "IP4.ADDRESS", "dev", "show", w.dev]; ipProc.running = true }
      }
    }
  }
  Process {
    id: ipProc
    stdout: StdioCollector {
      onStreamFinished: { var w = root.wired; root.wired = { conn: w.conn, state: w.state, dev: w.dev, ip: text.split("\n")[0].trim() } }
    }
  }
  Process {
    id: radioProc
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector { onStreamFinished: root.radioOn = text.trim() === "enabled" }
  }
  Process {
    id: knownProc
    command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        var k = {}, lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) { var f = root.split(lines[i]); if (f[1] === "802-11-wireless") k[f[0]] = true }
        root.known = k
      }
    }
  }
  Process {
    id: listProc
    command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
    stdout: StdioCollector {
      onStreamFinished: {
        var best = {}, lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var f = root.split(lines[i])
          if (f.length < 4 || f[1] === "") continue
          var n = { ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--", inUse: f[0] === "*" }
          var old = best[n.ssid]
          if (!old || n.inUse || (!old.inUse && n.signal > old.signal)) best[n.ssid] = n
        }
        var out = Object.keys(best).map(k => best[k])
        out.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
        root.networks = out.slice(0, 8)
      }
    }
  }
  Process { id: rescanProc; command: ["nmcli", "dev", "wifi", "rescan"] }

  function refresh() {
    statusProc.running = true
    radioProc.running = true
    knownProc.running = true
    listProc.running = true
  }
  Component.onCompleted: { refresh(); rescanProc.running = true; rescanTimer.start() }
  Timer { id: rescanTimer; interval: 2500; onTriggered: root.refresh() }
  Timer { interval: 6000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { id: afterConnect; interval: 3500; onTriggered: { root.busy = ""; root.refresh() } }

  // ---- actions
  function connect(n, password) {
    busy = n.ssid
    asking = ""
    var fail = 'notify-send -a Network "Wi-Fi" "Could not connect to $1"'
    if (known[n.ssid])
      Quickshell.execDetached(["sh", "-c", 'nmcli con up id "$1" >/dev/null 2>&1 || ' + fail, "_", n.ssid])
    else if (password !== undefined)
      Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$2" | nmcli --ask dev wifi connect "$1" >/dev/null 2>&1 || ' + fail, "_", n.ssid, password])
    else
      Quickshell.execDetached(["sh", "-c", 'nmcli dev wifi connect "$1" >/dev/null 2>&1 || ' + fail, "_", n.ssid])
    afterConnect.restart()
  }
  function disconnect(n) {
    Quickshell.execDetached(["sh", "-c", 'nmcli con down id "$1" >/dev/null 2>&1', "_", n.ssid])
    afterConnect.restart()
  }
  function setRadio(on) {
    radioOn = on
    Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
    if (!on) networks = []
    afterConnect.restart()
  }
  function strength(s) { return s > 75 ? 0xF0928 : s > 50 ? 0xF0925 : s > 25 ? 0xF0922 : 0xF091F }

  // ---- wired
  PanelHeader { text: "Wired"; visible: root.wired.dev !== "" }
  PanelRow {
    visible: root.wired.dev !== ""
    glyph: 0xF0200
    title: root.wired.state === "connected" ? root.wired.conn : "Not connected"
    subtitle: root.wired.state === "connected" ? (root.wired.ip !== "" ? root.wired.ip : "Connected") : root.wired.state
    active: root.wired.state === "connected"
    clickable: false
  }

  // ---- wi-fi
  PanelHeader {
    text: "Wi-Fi"
    visible: root.hasWifi
    PanelSwitch { checked: root.radioOn; onToggled: root.setRadio(!root.radioOn) }
  }
  Repeater {
    model: root.radioOn ? root.networks : []
    delegate: PanelRow {
      required property var modelData
      glyph: root.strength(modelData.signal)
      title: modelData.ssid
      subtitle: root.busy === modelData.ssid ? "Connecting…"
              : modelData.inUse ? "Connected · click to disconnect"
              : (root.known[modelData.ssid] ? "Saved" : modelData.secure ? "Secured" : "Open")
      trailing: modelData.secure ? Theme.icon(0xF033E) : ""
      active: modelData.inUse
      onClicked: {
        if (modelData.inUse) root.disconnect(modelData)
        else if (modelData.secure && !root.known[modelData.ssid]) { root.asking = modelData.ssid; pw.text = ""; pw.forceActiveFocus() }
        else root.connect(modelData)
      }
    }
  }
  Text {
    visible: root.hasWifi && root.radioOn && root.networks.length === 0
    leftPadding: Theme.s(18); topPadding: Theme.s(4); bottomPadding: Theme.s(10)
    text: "Searching for networks…"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }
  Text {
    visible: root.hasWifi && !root.radioOn
    leftPadding: Theme.s(18); topPadding: Theme.s(4); bottomPadding: Theme.s(10)
    text: "Wi-Fi is off"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }
  Text {
    visible: !root.hasWifi && root.wired.dev === ""
    leftPadding: Theme.s(18); topPadding: Theme.s(10); bottomPadding: Theme.s(14)
    text: "No network devices found"
    color: Theme.fgDim
    font { family: Theme.uiFont; pixelSize: Theme.s(13) }
  }

  // ---- password entry for a secured, unsaved network
  Item {
    visible: root.asking !== ""
    width: parent.width
    height: Theme.s(54)
    Rectangle {
      anchors { fill: parent; leftMargin: Theme.s(14); rightMargin: Theme.s(14); topMargin: Theme.s(6); bottomMargin: Theme.s(6) }
      radius: Theme.s(8)
      color: Theme.bgAlt
      border { width: 1; color: Theme.accent }
      TextInput {
        id: pw
        anchors { left: parent.left; leftMargin: Theme.s(12); right: go.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
        echoMode: TextInput.Password
        color: Theme.fg
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font { family: Theme.uiFont; pixelSize: Theme.s(14) }
        clip: true
        Text {
          visible: pw.text === ""
          text: "Password for " + root.asking
          color: Theme.tint(0.4)
          font: pw.font
          elide: Text.ElideRight
          width: parent.width
        }
        Keys.onReturnPressed: go.submit()
        Keys.onEnterPressed: go.submit()
        Keys.onEscapePressed: root.asking = ""
      }
      Text {
        id: go
        anchors { right: parent.right; rightMargin: Theme.s(12); verticalCenter: parent.verticalCenter }
        text: "Connect"
        color: Theme.accent
        font { family: Theme.uiFont; pixelSize: Theme.s(13); bold: true }
        function submit() {
          if (pw.text === "") return
          var n = root.networks.filter(x => x.ssid === root.asking)[0]
          if (n) root.connect(n, pw.text)
          pw.text = ""
        }
        MouseArea { anchors { fill: parent; margins: -6 } onClicked: go.submit() }
      }
    }
  }

  Item { width: 1; height: Theme.s(8) }
}
