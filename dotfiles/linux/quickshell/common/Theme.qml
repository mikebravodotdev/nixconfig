pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live theme. `theme-apply` writes ~/.local/state/quickshell/state.json (palette
// and wallpaper); this singleton watches it, so switching themes recolors the
// whole shell without a restart. Defaults below are used until a theme exists.
Singleton {
  id: root

  // ------------------------------------------------------------ state file
  readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/state.json"

  property var pal: ({})
  property string name: ""
  property string mode: "dark"
  property string wallpaper: ""

  FileView {
    path: root.stateFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var d = JSON.parse(text())
        root.pal = d.palette || ({})
        root.name = d.theme || ""
        root.mode = d.mode || "dark"
        root.wallpaper = d.background || ""
      } catch (e) { console.warn("Theme: bad state.json:", e) }
    }
  }

  function c(key, fallback) { return pal[key] !== undefined ? pal[key] : fallback }

  // ------------------------------------------------------------ palette
  readonly property color bg:      c("background", "#000000")
  readonly property color bgDark:  c("dark_background", "#000000")
  readonly property color bgAlt:   c("lighter_background", "#111111")
  readonly property color fg:      c("foreground", "#e6e6e6")
  readonly property color fgBright: c("bright_foreground", "#ffffff")
  readonly property color accent:  c("accent", "#33ccff")
  readonly property color accent2: c("cyan", c("accent", "#00ff99"))
  readonly property color urgent:  c("red", "#ff5555")
  readonly property color border:  c("muted", "#595959")

  // ------------------------------------------------------------ derived
  // De-emphasised text: foreground pulled halfway toward the background.
  readonly property color fgDim: Qt.rgba((fg.r + bg.r) / 2, (fg.g + bg.g) / 2, (fg.b + bg.b) / 2, 1)
  // Cards and menus sit on the deepest background.
  readonly property color card: bgDark
  readonly property color scrim: Qt.rgba(bgDark.r, bgDark.g, bgDark.b, 0.72)
  // Text drawn on an accent-colored fill: dark on light accents, light on dark ones.
  readonly property color onAccent: accent.hslLightness > 0.55 ? bgDark : fgBright
  readonly property color onAccentSoft:  Qt.rgba(onAccent.r, onAccent.g, onAccent.b, 0.8)
  readonly property color onAccentFaint: Qt.rgba(onAccent.r, onAccent.g, onAccent.b, 0.6)

  // Foreground at a given opacity: hairlines, placeholders, key hints.
  function tint(alpha) { return Qt.rgba(fg.r, fg.g, fg.b, alpha) }

  // ------------------------------------------------------------ fonts and sizes
  function icon(cp) { return String.fromCodePoint(cp) }   // Nerd Font glyph by code point

  readonly property string font:     "Hack Nerd Font"   // bar, toasts, OSD, code-like text
  readonly property string uiFont:   "Noto Sans"
  readonly property int fontSize:    15
  readonly property int barHeight:   34
  readonly property int gap:         10
  // Scale for the launcher, panels, menus and toasts. 1.0 = the original sizes.
  readonly property real uiScale: 1.15
  function s(n) { return Math.round(n * uiScale) }

  readonly property int launcherRadius: s(12)   // Alfred-style rounded panels; the rest stays flat
}
