import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.components

Card {
    id: root
    title: "bluetooth"
    iconCode: 0xF00AF
    width: 380
    color: Theme.alpha(Theme.base, 0.94)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false

    // Connected → paired → discovered (only ones with a name)
    readonly property var devices: (adapter?.devices.values ?? []).slice()
        .filter(d => d.paired || (d.deviceName && !/^([0-9A-F]{2}[-:]){5}/i.test(d.deviceName)))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    // Scan for devices while the menu is open
    Component.onCompleted: if (on) adapter.discovering = true
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false
    onOnChanged: if (on) adapter.discovering = true

    function icon(d) {
        const i = d.icon ?? "";
        if (i.includes("headset") || i.includes("headphone")) return 0xF02CB;
        if (i.includes("audio")) return 0xF04C3;
        if (i.includes("mouse")) return 0xF037D;
        if (i.includes("keyboard")) return 0xF030C;
        if (i.includes("phone")) return 0xF011C;
        if (i.includes("gaming")) return 0xF0297;
        return 0xF00AF;
    }

    function status(d) {
        if (d.pairing) return I18n.t("pairing…", "сопряжение…");
        if (d.state === BluetoothDeviceState.Connecting) return I18n.t("connecting…", "подключение…");
        if (d.state === BluetoothDeviceState.Disconnecting) return I18n.t("disconnecting…", "отключение…");
        if (d.connected) return d.batteryAvailable ? Math.round(d.battery * 100) + "%" : I18n.t("connected", "подключено");
        if (d.paired) return I18n.t("paired", "сопряжено");
        return "";
    }

    function activate(d) {
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else { d.trusted = true; d.pair(); }
    }

    // ---------- Adapter on/off ----------
    RowLayout {
        Layout.fillWidth: true
        Txt { text: Theme.icon(root.on ? 0xF00AF : 0xF00B2); font.pixelSize: 16
              color: root.on ? Theme.blue : Theme.muted }
        Txt { text: root.adapter?.name ?? "Bluetooth"; color: Theme.bright; Layout.fillWidth: true }
        Toggle {
            checked: root.on
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    RowLayout {
        visible: root.on
        Layout.fillWidth: true
        Section { text: I18n.t("DEVICES", "УСТРОЙСТВА"); Layout.fillWidth: true }
        Txt {
            visible: root.adapter?.discovering ?? false
            text: I18n.t("searching…", "поиск…")
            color: Theme.muted
            font.pixelSize: 10
            SequentialAnimation on opacity {
                running: root.adapter?.discovering ?? false
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
    }

    // ---------- Device list ----------
    ListView {
        visible: root.on
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        populate: PopulateFx {}
        model: root.devices

        delegate: Entry {
            id: dev
            required property var modelData
            width: ListView.view.width
            active: modelData.connected
            onClicked: root.activate(modelData)

            // New device: connect right after pairing
            Connections {
                target: dev.modelData
                function onPairedChanged() { if (dev.modelData.paired && !dev.modelData.connected) dev.modelData.connect(); }
            }

            Txt {
                text: Theme.icon(root.icon(dev.modelData))
                font.pixelSize: 15
                color: dev.modelData.connected ? Theme.blue : Theme.subtle
            }
            Txt {
                text: dev.modelData.name
                color: dev.modelData.connected ? Theme.bright : dev.modelData.paired ? Theme.text : Theme.subtle
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Txt {
                text: root.status(dev.modelData)
                color: dev.modelData.connected ? Theme.blue : Theme.muted
                font.pixelSize: 11
            }
            IconButton {
                visible: dev.modelData.paired && dev.hovered
                iconCode: 0xF0A7A   // forget
                font.pixelSize: 13
                onClicked: dev.modelData.forget()
            }
        }
    }

    Txt {
        visible: root.on && root.devices.length === 0
        text: I18n.t("no one nearby — put your device into pairing mode", "рядом никого — включите на устройстве режим сопряжения")
        color: Theme.muted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    // ---------- Bottom ----------
    Entry {
        onClicked: Popups.launch(["blueman-manager"])
        Txt { text: Theme.icon(0xF0493); color: Theme.muted }
        Txt { text: I18n.t("Advanced settings", "Расширенные настройки"); color: Theme.subtle; Layout.fillWidth: true }
    }
}
