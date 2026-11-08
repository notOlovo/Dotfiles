import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

Card {
    id: card
    title: loc.standaloneMonthName(month) + "  " + year
    iconCode: 0xF00ED   // calendar

    readonly property var loc: I18n.locale       // dates in the interface language
    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date today: clock.date

    // The shown month (scroll with the wheel or arrows)
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int month: shown.getMonth()
    readonly property int year: shown.getFullYear()

    // 42 cells, the week starts on Monday
    readonly property var cells: {
        const first = (shown.getDay() + 6) % 7;
        const res = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - first + i);
            res.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                isToday: d.toDateString() === today.toDateString(),
                weekend: i % 7 >= 5
            });
        }
        return res;
    }

    WheelHandler {
        onWheel: e => card.offset += e.angleDelta.y > 0 ? -1 : 1
    }

    RowLayout {
        Layout.fillWidth: true
        Txt {
            text: Theme.icon(0xF0141)
            color: navL.containsMouse ? Theme.bright : Theme.muted
            font.pixelSize: 16
            MouseArea { id: navL; anchors.fill: parent; hoverEnabled: true; onClicked: card.offset-- }
        }
        Item { Layout.fillWidth: true }
        Txt {
            visible: card.offset !== 0
            text: I18n.t("today", "сегодня")
            color: Theme.blue
            font.pixelSize: 11
            MouseArea { anchors.fill: parent; onClicked: card.offset = 0 }
        }
        Item { Layout.fillWidth: true }
        Txt {
            text: Theme.icon(0xF0142)
            color: navR.containsMouse ? Theme.bright : Theme.muted
            font.pixelSize: 16
            MouseArea { id: navR; anchors.fill: parent; hoverEnabled: true; onClicked: card.offset++ }
        }
    }

    GridLayout {
        columns: 7
        columnSpacing: 4
        rowSpacing: 4
        Layout.fillWidth: true

        Repeater {
            model: [1, 2, 3, 4, 5, 6, 0].map(d => card.loc.dayName(d, Locale.ShortFormat).toLowerCase())   // mon … sun
            Txt {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: index >= 5 ? Theme.violet : Theme.subtle
                font.pixelSize: 11
            }
        }

        Repeater {
            model: card.cells
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 6
                color: modelData.isToday ? Theme.alpha(Theme.blue, 0.18) : "transparent"
                border.width: modelData.isToday ? 1 : 0
                border.color: Theme.blue

                Txt {
                    anchors.centerIn: parent
                    text: parent.modelData.day
                    font.pixelSize: 12
                    font.weight: parent.modelData.isToday ? Font.Bold : Font.Normal
                    color: parent.modelData.isToday ? Theme.bright
                         : !parent.modelData.inMonth ? Theme.alpha(Theme.muted, 0.6)
                         : parent.modelData.weekend ? Theme.violet : Theme.text
                }
            }
        }
    }
}
