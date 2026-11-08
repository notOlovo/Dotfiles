import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Card {
    id: card
    title: I18n.t("system", "система")
    iconCode: 0xF061A   // chip

    function tempColor(t) { return t >= 85 ? Theme.rose : t >= 70 ? Theme.violet : Theme.text; }

    RowLayout {
        Layout.fillWidth: true
        Ring { value: Stats.cpu; label: "CPU"; Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true }
        Ring { value: Stats.ram; label: "RAM"; Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true }
        Ring { value: Stats.gpu; label: "GPU"; Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        RowLayout {
            Layout.fillWidth: true
            Txt { text: I18n.t("CPU load", "загрузка CPU"); color: Theme.muted; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Txt { text: I18n.t("~80 s", "~80 с"); color: Theme.muted; font.pixelSize: 10 }
        }
        Sparkline {
            Layout.fillWidth: true
            values: Stats.cpuHistory
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Stat { iconCode: 0xF050F; label: I18n.t("temperature", "температура")
               value: Math.round(Stats.cpuTemp) + "° cpu · " + Math.round(Stats.gpuTemp) + "° gpu · "
                      + Math.round(Stats.ssdTemp) + "° ssd"
               valueColor: card.tempColor(Math.max(Stats.cpuTemp, Stats.gpuTemp)) }
        Stat { iconCode: 0xF035B; label: I18n.t("memory", "память")
               value: Stats.ramUsed.toFixed(1) + " / " + Stats.ramTotal.toFixed(1) + " GiB" }
        Stat { iconCode: 0xF02CA; label: I18n.t("disk /", "диск /")
               value: Math.round(Stats.diskUsed) + " / " + Math.round(Stats.diskTotal) + " GiB" }
        Stat { iconCode: 0xF06F4; label: I18n.t("network", "сеть")   // swap-vertical
               value: "↓ " + Stats.fmtSpeed(Stats.netDown) + "   ↑ " + Stats.fmtSpeed(Stats.netUp) }
        Stat {
            visible: Stats.battery >= 0
            iconCode: Stats.batteryStatus === "Charging" ? 0xF0084 : 0xF0079
            label: I18n.t("battery", "батарея")
            value: Stats.battery + "%" + (Stats.batteryWatts > 0.1 ? "  ·  " + Stats.batteryWatts.toFixed(1) + I18n.t(" W", " Вт") : "")
            valueColor: Stats.battery <= 15 ? Theme.rose : Stats.batteryStatus === "Charging" ? Theme.blue : Theme.text
        }
    }
}
