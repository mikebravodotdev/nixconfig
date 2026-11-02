import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Qt5Compat.GraphicalEffects
import qs.common

// Lock screen: ext-session-lock via WlSessionLock, password check via PAM.
// While locked the compositor shows only these surfaces and sends input only to them.
//
// Locking:   quickshell ipc call lock lock   (hypridle and Super+Ctrl+L go through `lock-screen`)
// Unlocking: only a correct password. There is deliberately no unlock command.
//
// Safety net: if this shell dies while locked, Hyprland keeps the session locked
// (allow_session_lock_restore lets a new lock client take it over). Recover with
// `hyprlock` from another TTY, or restart quickshell and lock again.
Scope {
  id: root

  readonly property string userName: Quickshell.env("USER") || "user"
  readonly property alias locked: sessionLock.locked

  property string password: ""
  property bool checking: false
  property bool failed: false
  property string message: ""
  property int failCount: 0

  function lock() {
    if (sessionLock.locked) return
    reset()
    sessionLock.locked = true
  }

  function reset() {
    password = ""
    checking = false
    failed = false
    message = ""
  }

  function submit() {
    if (checking || password === "") return
    checking = true
    failed = false
    message = ""
    pam.start()
  }

  function fail() {
    checking = false
    password = ""
    failed = true
    failCount++
    message = "Incorrect password"
  }

  function respond() {
    if (pam.responseRequired) pam.respond(password)
  }

  // /etc/pam.d/hyprlock just includes the system's common-auth.
  PamContext {
    id: pam
    config: "hyprlock"
    user: root.userName

    onPamMessage: root.respond()
    onResponseRequiredChanged: root.respond()

    onCompleted: result => {
      console.log("lock: pam completed:", result === PamResult.Success ? "success" : "failed")
      if (result === PamResult.Success) {
        root.reset()
        sessionLock.locked = false
      } else {
        root.fail()
      }
    }
    onError: err => {
      console.warn("lock: pam error:", err)
      root.fail()
      root.message = "Authentication error"
    }
  }

  WlSessionLock {
    id: sessionLock
    locked: false

    WlSessionLockSurface {
      id: surface
      color: Theme.bgDark

      Item {
        id: view
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()

        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 250; running: true }

        // ---------------------------------------------------------- input
        Keys.onPressed: event => {
          event.accepted = true
          if (root.checking) return
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.submit(); return }
          var plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
          if (event.key === Qt.Key_Backspace) {
            root.password = (event.modifiers & Qt.ControlModifier) ? "" : root.password.slice(0, -1)
          } else if (event.key === Qt.Key_Escape) {
            root.password = ""
          } else if (plain && event.text.length === 1 && event.text >= " ") {
            root.password += event.text
          } else {
            return
          }
          if (root.failed) { root.failed = false; root.message = "" }
        }

        // ---------------------------------------------------------- background
        Image {
          id: wall
          anchors.fill: parent
          source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
          sourceSize.width: 1920               // it gets blurred, so decode small
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: false
        }
        FastBlur {
          anchors.fill: parent
          source: wall
          radius: 64
          visible: wall.status === Image.Ready
        }
        Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: wall.status === Image.Ready ? 0.55 : 1 }

        // ---------------------------------------------------------- clock
        Column {
          id: clockBox
          anchors { horizontalCenter: parent.horizontalCenter; bottom: card.top; bottomMargin: 56 }
          spacing: 4

          Text {
            id: time
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "HH:mm")
            color: Theme.fgBright
            font { family: Theme.uiFont; pixelSize: 132; weight: Font.Light }
          }
          Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
            color: Theme.fgDim
            font { family: Theme.uiFont; pixelSize: 24 }
          }
          Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: { time.text = Qt.formatTime(new Date(), "HH:mm"); date.text = Qt.formatDate(new Date(), "dddd, d MMMM") }
          }
        }

        // ---------------------------------------------------------- password card
        Rectangle {
          id: card
          width: 420; height: 60
          anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 40 }
          radius: Theme.launcherRadius
          color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.88)
          border {
            width: 2
            color: root.failed ? Theme.urgent : (root.checking ? Theme.accent2 : Theme.tint(0.25))
          }
          Behavior on border.color { ColorAnimation { duration: 120 } }

          transform: Translate { id: shake }
          SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 14;  duration: 80 }
            NumberAnimation { target: shake; property: "x"; to: -9;  duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: 6;   duration: 60 }
            NumberAnimation { target: shake; property: "x"; to: 0;   duration: 50 }
          }
          Connections { target: root; function onFailCountChanged() { shakeAnim.restart() } }

          Text {
            id: lockGlyph
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            text: Theme.icon(root.checking ? 0xF0996 : 0xF033E)
            color: root.failed ? Theme.urgent : Theme.accent
            font { family: Theme.uiFont; pixelSize: 22 }
          }

          Text {
            visible: root.password === ""
            anchors { left: lockGlyph.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text: root.checking ? "Checking…" : "Enter password"
            color: Theme.tint(0.4)
            font { family: Theme.uiFont; pixelSize: 17 }
          }

          Row {
            anchors { left: lockGlyph.right; leftMargin: 16; right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
            spacing: 8
            clip: true
            Repeater {
              model: Math.min(root.password.length, 22)
              delegate: Rectangle { width: 10; height: 10; radius: 5; color: Theme.fgBright }
            }
          }
        }

        // ---------------------------------------------------------- status line
        Text {
          anchors { horizontalCenter: parent.horizontalCenter; top: card.bottom; topMargin: 18 }
          text: root.message
          color: root.failed ? Theme.urgent : Theme.fgDim
          font { family: Theme.uiFont; pixelSize: 15 }
        }

        // ---------------------------------------------------------- user
        Text {
          anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
          text: Theme.icon(0xF0004) + "  " + root.userName
          color: Theme.fgDim
          font { family: Theme.uiFont; pixelSize: 14 }
        }
      }
    }
  }
}
