import QtQuick
import Quickshell.Services.Pipewire
import qs.common
import qs.components

// Output and input devices, their volumes, and per-app volumes.
Column {
  id: root
  width: Theme.s(400)

  readonly property var allNodes: Pipewire.nodes.values
  PwObjectTracker { objects: root.allNodes }

  readonly property var sinks:   allNodes.filter(n => n.isSink && !n.isStream && n.audio)
  readonly property var sources: allNodes.filter(n => !n.isSink && !n.isStream && n.audio)
  readonly property var apps:    allNodes.filter(n => n.isSink && n.isStream && n.audio)

  function label(n) { return n.description || n.nickname || n.name }
  function appName(n) { return (n.properties && (n.properties["application.name"] || n.properties["media.name"])) || n.name }

  // ---- output
  PanelHeader { text: "Output" }
  PanelSlider {
    visible: Pipewire.defaultAudioSink !== null && Pipewire.defaultAudioSink.audio !== null
    glyph: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? 0xF075F : 0xF057E
    value: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
    muted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.muted : false
    onMoved: v => { if (Pipewire.defaultAudioSink.audio) { Pipewire.defaultAudioSink.audio.muted = false; Pipewire.defaultAudioSink.audio.volume = v } }
    onGlyphClicked: Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
  }
  Repeater {
    model: root.sinks
    delegate: PanelRow {
      required property var modelData
      glyph: 0xF04C3
      title: root.label(modelData)
      active: Pipewire.defaultAudioSink === modelData
      trailing: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
      onClicked: Pipewire.preferredDefaultAudioSink = modelData
    }
  }

  // ---- input
  PanelHeader { text: "Input" }
  PanelSlider {
    visible: Pipewire.defaultAudioSource !== null && Pipewire.defaultAudioSource.audio !== null
    glyph: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted ? 0xF036D : 0xF036C
    value: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.volume : 0
    muted: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.muted : false
    onMoved: v => { if (Pipewire.defaultAudioSource.audio) { Pipewire.defaultAudioSource.audio.muted = false; Pipewire.defaultAudioSource.audio.volume = v } }
    onGlyphClicked: Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
  }
  Repeater {
    model: root.sources
    delegate: PanelRow {
      required property var modelData
      glyph: 0xF036C
      title: root.label(modelData)
      active: Pipewire.defaultAudioSource === modelData
      trailing: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
      onClicked: Pipewire.preferredDefaultAudioSource = modelData
    }
  }

  // ---- applications
  PanelHeader { text: "Applications"; visible: root.apps.length > 0 }
  Repeater {
    model: root.apps
    delegate: Column {
      required property var modelData
      width: root.width
      Text {
        leftPadding: Theme.s(18)
        text: root.appName(modelData)
        color: Theme.fgDim
        font { family: Theme.uiFont; pixelSize: Theme.s(11) }
      }
      PanelSlider {
        glyph: modelData.audio.muted ? 0xF075F : 0xF057E
        value: modelData.audio.volume
        muted: modelData.audio.muted
        height: Theme.s(36)
        onMoved: v => { modelData.audio.muted = false; modelData.audio.volume = v }
        onGlyphClicked: modelData.audio.muted = !modelData.audio.muted
      }
    }
  }

  Item { width: 1; height: Theme.s(8) }
}
