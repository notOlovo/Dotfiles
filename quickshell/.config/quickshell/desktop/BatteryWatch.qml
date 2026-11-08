import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Low battery warnings: 20% and 10% — a notification, 5% — fullscreen.
// Each threshold fires once per discharge; charging resets them.
Scope {
    id: root

    readonly property int level: Stats.battery
    readonly property bool discharging: Stats.batteryStatus === "Discharging"

    property int warned: 101          // the lowest threshold already warned about
    property bool critical: false

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", I18n.t("Battery", "Батарея"), "-u", urgency, "-i", "battery-caution", title, body]);
    }

    function check() {
        if (level < 0) return;
        if (!discharging) { warned = 101; critical = false; return; }
        if (level <= 5 && warned > 5) {
            warned = 5;
            critical = true;
        } else if (level <= 10 && warned > 10) {
            warned = 10;
            notify("critical", I18n.t("Battery 10%", "Батарея 10%"), I18n.t("Plug in the charger — the laptop will sleep soon.", "Подключите зарядку — скоро ноутбук уснёт."));
        } else if (level <= 20 && warned > 20) {
            warned = 20;
            notify("normal", I18n.t("Battery 20%", "Батарея 20%"), I18n.t("Time to think about charging.", "Пора подумать о зарядке."));
        }
    }

    onLevelChanged: check()
    onDischargingChanged: check()

    LazyLoader {
        active: root.critical

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-battery"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.alpha(Theme.voidColor, 0.7)

            MouseArea { anchors.fill: parent; onClicked: root.critical = false }

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onPressed: root.critical = false

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: Theme.icon(0xF0083)       // battery-alert
                        color: Theme.rose
                        font.pixelSize: 96
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                        }
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.t("Battery ", "Батарея ") + root.level + "%"
                        color: Theme.bright
                        font.pixelSize: 40
                        font.weight: Font.Light
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.t("Plug in the charger, or the laptop will shut down soon", "Подключите зарядку, иначе ноутбук скоро выключится")
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 16
                        text: I18n.t("click or any key — hide", "клик или любая клавиша — скрыть")
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
