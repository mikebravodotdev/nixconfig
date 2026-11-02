pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery state from UPower: the main (laptop) battery, plus batteries in
// wireless mice, keyboards, headsets and so on. Also sends low-charge warnings.
Singleton {
  id: root

  // Simulated battery for previewing the UI on a machine without one (see the `battery` IPC
  // target in shell.qml). null = use the real UPower data.
  property var mock: null

  // ------------------------------------------------------------ main battery
  readonly property var dev: UPower.displayDevice
  readonly property bool hasMain: mock !== null ? !!mock.main : !!(dev && dev.isPresent)
  readonly property real fraction: mock !== null ? mock.percent / 100
                                  : (hasMain ? Math.max(0, Math.min(1, Number(dev.percentage || 0))) : 0)
  readonly property int percent: Math.round(fraction * 100)

  // "charging" | "discharging" | "full" | "plugged" (on AC but not charging) | "unknown"
  readonly property string state: {
    if (mock !== null) return mock.state
    if (!hasMain) return "unknown"
    if (dev.state === UPowerDeviceState.Charging) return "charging"
    if (dev.state === UPowerDeviceState.Discharging) return "discharging"
    if (dev.state === UPowerDeviceState.FullyCharged) return "full"
    if (dev.state === UPowerDeviceState.PendingCharge) return "plugged"
    return UPower.onBattery ? "discharging" : "unknown"
  }
  readonly property bool charging: state === "charging"
  readonly property bool discharging: state === "discharging"

  // Details, 0 when unknown.
  readonly property real secondsLeft: mock !== null ? (mock.seconds || 0)
                                    : (!hasMain ? 0 : (discharging ? Number(dev.timeToEmpty || 0) : charging ? Number(dev.timeToFull || 0) : 0))
  readonly property real watts: mock !== null ? (mock.watts || 0) : (hasMain ? Math.abs(Number(dev.changeRate || 0)) : 0)
  readonly property real health: mock !== null ? (mock.health || 0) : (hasMain ? Number(dev.healthPercentage || 0) : 0)
  readonly property real energy: mock !== null ? (mock.energy || 0) : (hasMain ? Number(dev.energy || 0) : 0)
  readonly property real energyFull: mock !== null ? (mock.energyFull || 0) : (hasMain ? Number(dev.energyCapacity || 0) : 0)

  // ------------------------------------------------------------ peripherals
  // Normalised to { id, name, percent, kind }.
  readonly property var peripherals: {
    if (mock !== null) return mock.peripherals || []
    var out = []
    var list = UPower.devices ? UPower.devices.values : []
    for (var i = 0; i < list.length; i++) {
      var d = list[i]
      if (!d || !d.isPresent || d.isLaptopBattery || d.type === UPowerDeviceType.LinePower) continue
      var p = Math.round(Number(d.percentage || 0) * 100)
      if (p <= 0 && d.state === UPowerDeviceState.Unknown) continue
      out.push({ id: d.nativePath || d.model || String(i), name: d.model || d.nativePath || "Device", percent: p, kind: d.type })
    }
    return out
  }
  readonly property int lowestPeripheral: peripherals.length === 0 ? -1 : Math.min.apply(null, peripherals.map(p => p.percent))

  // What the bar shows: the main battery, or the emptiest peripheral when there is none.
  readonly property bool shown: hasMain || peripherals.length > 0
  readonly property int barPercent: hasMain ? percent : lowestPeripheral
  readonly property bool barCharging: hasMain && charging
  readonly property bool low: barPercent >= 0 && barPercent <= 15 && !barCharging && (hasMain ? discharging : true)

  // ------------------------------------------------------------ helpers
  function duration(sec) {
    if (!sec || sec <= 0) return ""
    var h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60)
    if (m === 60) { h++; m = 0 }
    return h > 0 ? h + " h " + (m < 10 ? "0" : "") + m + " min" : m + " min"
  }

  readonly property string statusText: {
    if (!hasMain) return ""
    if (state === "full") return "Fully charged"
    if (state === "plugged") return "Plugged in, not charging"
    var t = duration(secondsLeft)
    if (state === "charging") return "Charging" + (t !== "" ? " · " + t + " until full" : "")
    if (state === "discharging") return "On battery" + (t !== "" ? " · " + t + " left" : "")
    return ""
  }

  // ------------------------------------------------------------ low-charge warnings
  property int notifiedLevel: 101       // lowest threshold already announced this discharge
  property bool primed: false
  property var notifiedPeripherals: ({})

  function notify(urgency, title, body) {
    Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, title, body])
  }

  function checkMain() {
    if (!hasMain || !discharging) { notifiedLevel = 101; primed = hasMain; return }
    var t = percent <= 5 ? 5 : percent <= 10 ? 10 : percent <= 20 ? 20 : 101
    if (!primed) { primed = true; notifiedLevel = t; return }   // don't announce what was already true at startup
    if (t < notifiedLevel) {
      notifiedLevel = t
      if (t === 20) notify("normal", "Battery low", percent + "% remaining. Plug in soon.")
      else if (t === 10) notify("critical", "Battery very low", percent + "% remaining.")
      else if (t === 5) notify("critical", "Battery critically low", percent + "% remaining. Plug in now.")
    }
  }
  function checkPeripherals() {
    var seen = Object.assign({}, notifiedPeripherals)
    for (var i = 0; i < peripherals.length; i++) {
      var p = peripherals[i]
      if (p.percent > 30) delete seen[p.id]
      else if (p.percent <= 15 && !seen[p.id]) { seen[p.id] = true; notify("normal", p.name + " battery low", p.percent + "% remaining.") }
    }
    notifiedPeripherals = seen
  }

  onPercentChanged: checkMain()
  onStateChanged: checkMain()
  onHasMainChanged: checkMain()
  onPeripheralsChanged: checkPeripherals()
  Component.onCompleted: checkMain()
}
