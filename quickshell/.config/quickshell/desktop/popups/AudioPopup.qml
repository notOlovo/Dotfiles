import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services
import qs.components

Card {
    id: root
    title: I18n.t("sound", "звук")
    iconCode: 0xF057E
    width: 380
    color: Theme.alpha(Theme.base, 0.94)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function cls(n) { return n.properties?.["media.class"] ?? ""; }
    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks:   nodes.filter(n => cls(n) === "Audio/Sink")
    readonly property var sources: nodes.filter(n => cls(n) === "Audio/Source")
    readonly property var streams: nodes.filter(n => cls(n) === "Stream/Output/Audio")

    // Properties (class, description, volume) only arrive for tracked nodes —
    // so track all of them, not the already filtered ones
    PwObjectTracker { objects: root.nodes }

    function label(n) { return n?.description || n?.nickname || n?.name || "—"; }

    function volumeIcon(a) {
        if (!a || a.muted) return 0xF075F;
        return a.volume > 0.66 ? 0xF057E : a.volume > 0.33 ? 0xF0580 : 0xF057F;
    }

    function deviceIcon(n) {
        const name = n?.name ?? "";
        if (name.startsWith("bluez")) return 0xF02CB;
        if (/hdmi|displayport/i.test(name)) return 0xF0379;
        return 0xF04C3;
    }

    // ---------- Output ----------
    Section { text: I18n.t("OUTPUT", "ВЫХОД") }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        IconButton {
            iconCode: root.volumeIcon(root.sink?.audio)
            active: !(root.sink?.audio?.muted ?? true)
            onClicked: root.sink.audio.muted = !root.sink.audio.muted
        }
        Slider {
            Layout.fillWidth: true
            value: root.sink?.audio?.volume ?? 0
            color: root.sink?.audio?.muted ? Theme.muted : Theme.blue
            onMoved: v => { root.sink.audio.muted = false; root.sink.audio.volume = v; }
        }
        Txt {
            text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.text
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    Repeater {
        model: root.sinks
        Entry {
            id: out
            required property var modelData
            active: modelData.id === root.sink?.id
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
            Txt { text: Theme.icon(root.deviceIcon(out.modelData)); font.pixelSize: 15
                  color: out.active ? Theme.blue : Theme.subtle }
            Txt { text: root.label(out.modelData); Layout.fillWidth: true; elide: Text.ElideRight
                  color: out.active ? Theme.bright : Theme.text }
        }
    }

    // ---------- Microphone ----------
    Section { text: I18n.t("MICROPHONE", "МИКРОФОН"); visible: root.source !== null }

    RowLayout {
        visible: root.source !== null
        Layout.fillWidth: true
        spacing: 12
        IconButton {
            iconCode: root.source?.audio?.muted ? 0xF036D : 0xF036C
            active: !(root.source?.audio?.muted ?? true)
            onClicked: root.source.audio.muted = !root.source.audio.muted
        }
        Slider {
            Layout.fillWidth: true
            value: root.source?.audio?.volume ?? 0
            color: root.source?.audio?.muted ? Theme.muted : Theme.violet
            onMoved: v => { root.source.audio.muted = false; root.source.audio.volume = v; }
        }
        Txt {
            text: Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.text
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    Repeater {
        model: root.sources.length > 1 ? root.sources : []
        Entry {
            id: inp
            required property var modelData
            active: modelData.id === root.source?.id
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
            Txt { text: Theme.icon(0xF036C); font.pixelSize: 15
                  color: inp.active ? Theme.violet : Theme.subtle }
            Txt { text: root.label(inp.modelData); Layout.fillWidth: true; elide: Text.ElideRight
                  color: inp.active ? Theme.bright : Theme.text }
        }
    }

    // ---------- Apps ----------
    Section { text: I18n.t("APPS", "ПРИЛОЖЕНИЯ"); visible: root.streams.length > 0 }

    Repeater {
        model: root.streams
        ColumnLayout {
            required property var modelData
            readonly property var props: modelData.properties ?? {}
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                spacing: 8
                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(parent.parent.props["application.icon-name"]
                                                ?? (parent.parent.props["application.process.binary"] ?? ""), "audio-x-generic")
                }
                Txt {
                    Layout.fillWidth: true
                    text: parent.parent.props["application.name"] ?? root.label(parent.parent.modelData)
                    color: Theme.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
            RowLayout {
                spacing: 12
                IconButton {
                    iconCode: root.volumeIcon(parent.parent.modelData.audio)
                    font.pixelSize: 14
                    onClicked: parent.parent.modelData.audio.muted = !parent.parent.modelData.audio.muted
                }
                Slider {
                    Layout.fillWidth: true
                    value: parent.parent.modelData.audio?.volume ?? 0
                    color: Theme.cyan
                    onMoved: v => parent.parent.modelData.audio.volume = v
                }
                Txt {
                    text: Math.round((parent.parent.modelData.audio?.volume ?? 0) * 100) + "%"
                    color: Theme.subtle
                    font.pixelSize: 12
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // ---------- Bottom ----------
    Entry {
        onClicked: Popups.launch(["pavucontrol"])
        Txt { text: Theme.icon(0xF0493); color: Theme.muted }
        Txt { text: I18n.t("Advanced settings", "Расширенные настройки"); color: Theme.subtle; Layout.fillWidth: true }
    }
}
