import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.services
import qs.components

Card {
    id: root
    title: I18n.t("network", "сеть")
    iconCode: 0xF0928
    width: 380
    color: Theme.alpha(Theme.base, 0.94)

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null

    readonly property var networks: (wifi?.networks.values ?? []).slice()
        .filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    // The network whose password field is open
    property string askPassword: ""

    // Scan for networks while the menu is open
    Component.onCompleted: if (wifi) wifi.scannerEnabled = true
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false

    function signalIcon(s) {
        return s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F;
    }

    function status(n) {
        if (n.stateChanging) return n.connected ? I18n.t("disconnecting…", "отключение…") : I18n.t("connecting…", "подключение…");
        if (n.connected) return I18n.t("connected", "подключено");
        if (n.known) return I18n.t("saved", "сохранена");
        return "";
    }

    function activate(n) {
        if (n.connected) n.disconnect();
        else if (n.known || n.security === WifiSecurityType.Open) n.connect();
        else root.askPassword = root.askPassword === n.name ? "" : n.name;
    }

    // ---------- Wi-Fi on/off ----------
    RowLayout {
        Layout.fillWidth: true
        Txt { text: Theme.icon(Networking.wifiEnabled ? 0xF0928 : 0xF092D); font.pixelSize: 16
              color: Networking.wifiEnabled ? Theme.blue : Theme.muted }
        Txt { text: "Wi-Fi"; color: Theme.bright; Layout.fillWidth: true }
        Toggle {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Entry {
        visible: root.wired !== null
        active: true
        Txt { text: Theme.icon(0xF0200); color: Theme.blue }
        Txt { text: "Ethernet · " + (root.wired?.name ?? ""); color: Theme.bright; Layout.fillWidth: true }
        Txt { text: I18n.t("connected", "подключено"); color: Theme.blue; font.pixelSize: 11 }
    }

    Section {
        visible: Networking.wifiEnabled
        text: root.networks.length ? I18n.t("NETWORKS", "СЕТИ") : I18n.t("SEARCHING…", "ПОИСК СЕТЕЙ…")
    }

    // ---------- Network list ----------
    ListView {
        visible: Networking.wifiEnabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        populate: PopulateFx {}
        model: root.networks

        delegate: ColumnLayout {
            id: net
            required property var modelData
            width: ListView.view.width
            spacing: 4

            readonly property bool secured: modelData.security !== WifiSecurityType.Open

            Entry {
                active: net.modelData.connected
                onClicked: root.activate(net.modelData)

                Txt {
                    text: Theme.icon(root.signalIcon(net.modelData.signalStrength))
                    font.pixelSize: 15
                    color: net.modelData.connected ? Theme.blue : Theme.subtle
                }
                Txt {
                    text: net.modelData.name
                    color: net.modelData.connected ? Theme.bright : Theme.text
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Txt {
                    text: root.status(net.modelData)
                    color: net.modelData.connected ? Theme.blue : Theme.muted
                    font.pixelSize: 11
                }
                Txt {
                    visible: net.secured
                    text: Theme.icon(0xF033E)
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }

            // Password for a new secured network
            RowLayout {
                visible: root.askPassword === net.modelData.name
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.bottomMargin: 6
                spacing: 8

                Field {
                    id: psk
                    Layout.fillWidth: true
                    placeholder: I18n.t("password", "пароль")
                    password: true
                    onVisibleChanged: if (visible) input.forceActiveFocus()
                    onAccepted: {
                        net.modelData.connectWithPsk(text);
                        root.askPassword = "";
                    }
                }
                IconButton {
                    iconCode: 0xF0054   // arrow-right
                    activeColor: Theme.blue
                    active: true
                    onClicked: psk.accepted()
                }
            }
        }
    }

    // ---------- Bottom ----------
    Entry {
        onClicked: Popups.launch(["nm-connection-editor"])
        Txt { text: Theme.icon(0xF0493); color: Theme.muted }
        Txt { text: I18n.t("Network settings", "Настройки сети"); color: Theme.subtle; Layout.fillWidth: true }
    }
}
