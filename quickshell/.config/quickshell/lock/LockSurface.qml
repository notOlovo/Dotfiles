import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.components
import qs.cards

// Lock screen contents (one per monitor)
FocusScope {
    id: s

    required property var ctx            // ShellRoot: password, checking, error, unlocking, tryUnlock()
    focus: true

    // Appearing: the background fades in, the clock floats up; unlocking — everything fades and rises
    property real reveal: 0
    Component.onCompleted: revealAnim.start()
    NumberAnimation { id: revealAnim; target: s; property: "reveal"; from: 0; to: 1; duration: 700; easing.type: Easing.OutQuint }
    opacity: ctx.unlocking ? 0 : Math.min(1, reveal * 1.6)
    Behavior on opacity { enabled: s.ctx.unlocking; NumberAnimation { duration: 360; easing.type: Easing.InCubic } }

    readonly property var loc: I18n.locale       // dates in the interface language
    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ---- Wallpaper from waypaper, blurred and dimmed ----
    property string wallpaper: ""
    FileView {
        path: Quickshell.env("HOME") + "/.config/waypaper/config.ini"
        printErrors: false
        onLoaded: {
            const m = text().match(/^wallpaper\s*=\s*(.+)$/m);
            if (m) s.wallpaper = m[1].trim().replace(/^~/, Quickshell.env("HOME"));
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.voidColor }

    Image {
        id: wall
        anchors.fill: parent
        source: s.wallpaper ? "file://" + s.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1280      // a blurred background doesn't need full resolution
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: -0.35
        saturation: -0.2
        opacity: wall.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.voidColor, 0.35) }

    // ---- Keyboard layout (matters for the password) ----
    property string layout: ""
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kb = JSON.parse(text).keyboards.find(k => k.main);
                if (kb) s.layout = kb.active_keymap;
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "activelayout") s.layout = e.data.split(",").slice(1).join(",");
        }
    }
    readonly property string layoutShort: /russian/i.test(layout) ? "RU" : layout ? "EN" : ""

    // ---- Center: clock, date, password ----
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40 + (1 - s.reveal) * 30 - (s.ctx.unlocking ? 30 : 0)
        Behavior on anchors.verticalCenterOffset { enabled: s.ctx.unlocking; NumberAnimation { duration: 360; easing.type: Easing.InCubic } }
        scale: 0.96 + 0.04 * s.reveal
        spacing: 6

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.bright
            font.pixelSize: 128
            font.weight: Font.ExtraLight
            font.letterSpacing: -3
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.blue
                shadowBlur: 1.0
                shadowOpacity: 0.6
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: clock.date.toLocaleDateString(s.loc, "dddd, d MMMM")
            color: Theme.text
            font.pixelSize: 20
            font.weight: Font.Light
        }

        Item { Layout.preferredHeight: 46 }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: Quickshell.env("USER") ?? ""
            color: Theme.subtle
            font.pixelSize: 13
            font.letterSpacing: 2
        }

        // Password field
        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitWidth: 320
            implicitHeight: 48
            radius: 24
            color: Theme.alpha(Theme.base, 0.75)
            border.width: 1
            border.color: s.ctx.error ? Theme.rose : input.activeFocus ? Theme.alpha(Theme.blue, 0.8) : Theme.overlay
            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Shake on error
            property real shake: 0
            transform: Translate { x: field.shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: field; property: "shake"; to: -10; duration: 50 }
                NumberAnimation { target: field; property: "shake"; to: 10; duration: 70 }
                NumberAnimation { target: field; property: "shake"; to: -6; duration: 60 }
                NumberAnimation { target: field; property: "shake"; to: 0; duration: 60 }
            }
            Connections {
                target: s.ctx
                function onErrorChanged() { if (s.ctx.error) shakeAnim.restart(); }
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 52
                anchors.rightMargin: 52   // symmetric: the center matches the placeholder
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                focus: true
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 18
                cursorDelegate: Item {}   // custom cursor below
                enabled: !s.ctx.checking
                text: s.ctx.password
                onTextChanged: { s.ctx.password = text; if (text) s.ctx.error = ""; }
                onAccepted: s.ctx.tryUnlock()
                Component.onCompleted: forceActiveFocus()
            }

            Txt {
                id: hint
                anchors.centerIn: parent
                visible: input.text === ""
                text: s.ctx.checking ? I18n.t("checking…", "проверяю…") : I18n.t("password", "пароль")
                color: Theme.muted
                font.pixelSize: 14
            }

            // Cursor: before the placeholder when empty, after the last dot while typing
            Rectangle {
                id: caret
                width: 2
                height: 20
                radius: 1
                color: Theme.blue
                anchors.verticalCenter: parent.verticalCenter
                x: input.text === "" ? hint.x - width - 6
                                      : input.x + input.cursorRectangle.x + 3
                visible: input.activeFocus && !s.ctx.checking

                // Blinks in pauses, steady while typing
                SequentialAnimation on opacity {
                    id: blink
                    loops: Animation.Infinite
                    running: caret.visible
                    PropertyAction { value: 1 }
                    PauseAnimation { duration: 500 }
                    NumberAnimation { to: 0; duration: 350; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 350; easing.type: Easing.InOutSine }
                }
                Connections {
                    target: input
                    function onTextChanged() { blink.restart(); }
                }
            }

            // Layout indicator on the right of the field
            Txt {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: s.layoutShort
                color: s.layoutShort === "RU" ? Theme.violet : Theme.muted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: s.ctx.error
            color: Theme.rose
            font.pixelSize: 12
            opacity: s.ctx.error ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    // ---- Bottom left: weather ----
    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 12
        visible: Weather.ready
        Txt {
            text: Weather.icon(Weather.current.weather_code, Weather.current.is_day)
            color: Theme.cyan
            font.pixelSize: 30
        }
        ColumnLayout {
            spacing: 0
            Txt { text: Math.round(Weather.current.temperature_2m ?? 0) + "°  " + Weather.city; color: Theme.bright; font.pixelSize: 16 }
            Txt { text: Weather.describe(Weather.current.weather_code); color: Theme.subtle; font.pixelSize: 12 }
        }
    }

    // ---- Bottom center: player ----
    PlayerCard {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        width: 360
    }

    // ---- Bottom right: battery ----
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 8
        visible: Stats.battery >= 0
        Txt {
            text: Theme.icon(Stats.batteryStatus === "Charging" ? 0xF0084 : 0xF0079)
            color: Stats.battery <= 15 ? Theme.rose : Stats.batteryStatus === "Charging" ? Theme.blue : Theme.subtle
            font.pixelSize: 18
        }
        Txt { text: Stats.battery + "%"; color: Theme.text; font.pixelSize: 14 }
    }
}
