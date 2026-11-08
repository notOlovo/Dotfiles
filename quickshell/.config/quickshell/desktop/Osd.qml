import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Volume / brightness / microphone indicator at the bottom center.
// Called from media.sh: qs ipc -c desktop call osd volume|brightness|mic
Scope {
    id: root

    property string kind: ""          // volume | brightness | mic
    property bool shown: false
    property bool alive: false        // the window lives while the exit animation plays

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    property real brightness: 0

    FileView {
        id: blMax
        path: "/sys/class/backlight/" + backlight.name + "/max_brightness"
        printErrors: false
    }
    FileView {
        id: blCur
        path: "/sys/class/backlight/" + backlight.name + "/brightness"
        printErrors: false
        onLoaded: root.brightness = Number(text()) / Math.max(1, Number(blMax.text()))
    }
    // Backlight device name (amdgpu_bl1 etc.)
    QtObject { id: backlight; property string name: "" }
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        stdout: StdioCollector { onStreamFinished: backlight.name = text.trim() }
    }

    function show(k) {
        kind = k;
        if (k === "brightness") { blMax.reload(); blCur.reload(); }
        alive = true;
        shown = true;
        hide.restart();
    }

    Timer { id: hide; interval: 1400; onTriggered: { root.shown = false; destroyLater.restart(); } }
    Timer { id: destroyLater; interval: 260; onTriggered: if (!root.shown) root.alive = false }

    IpcHandler {
        target: "osd"
        function volume(): void { root.show("volume"); }
        function brightness(): void { root.show("brightness"); }
        function mic(): void { root.show("mic"); }
    }

    readonly property bool muted: kind === "volume" ? (sink?.audio?.muted ?? false)
                                : kind === "mic" ? (source?.audio?.muted ?? false) : false
    readonly property real value: kind === "volume" ? (sink?.audio?.volume ?? 0)
                                : kind === "mic" ? (source?.audio?.volume ?? 0) : brightness

    readonly property int iconCode: {
        if (kind === "brightness") return value > 0.66 ? 0xF00E0 : value > 0.33 ? 0xF00DF : 0xF00DE;
        if (kind === "mic") return muted ? 0xF036D : 0xF036C;
        if (muted || value === 0) return 0xF075F;
        return value > 0.66 ? 0xF057E : value > 0.33 ? 0xF0580 : 0xF057F;
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-osd"
            exclusionMode: ExclusionMode.Ignore
            anchors.bottom: true
            margins.bottom: 70
            implicitWidth: 300
            implicitHeight: 52
            color: "transparent"
            // Doesn't grab the mouse
            mask: Region {}

            Rectangle {
                id: box
                anchors.fill: parent
                radius: 26
                color: Theme.alpha(Theme.base, 0.92)
                border.width: 1
                border.color: Theme.alpha(Theme.overlay, 0.9)

                // Slides up and fades in; slides down fading out
                property bool entered: false
                Component.onCompleted: Qt.callLater(() => entered = true)
                readonly property bool on: entered && root.shown

                opacity: on ? 1 : 0
                scale: on ? 1 : 0.92
                transform: Translate {
                    y: box.on ? 0 : 14
                    Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 14

                    Txt {
                        text: Theme.icon(root.iconCode)
                        font.pixelSize: 20
                        color: root.muted ? Theme.muted : root.kind === "brightness" ? Theme.violet : Theme.blue
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.overlay

                        Rectangle {
                            width: parent.width * Math.min(1, root.value)
                            height: parent.height
                            radius: 3
                            color: root.muted ? Theme.muted : root.kind === "brightness" ? Theme.violet : Theme.blue
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }

                    Txt {
                        text: root.muted ? I18n.t("off", "выкл") : Math.round(root.value * 100) + "%"
                        color: Theme.text
                        font.pixelSize: 13
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
