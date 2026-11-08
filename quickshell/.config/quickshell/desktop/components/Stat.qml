import QtQuick
import QtQuick.Layouts
import qs.services

// A row "icon  label ........ value"
RowLayout {
    property int iconCode: 0
    property string label: ""
    property string value: ""
    property color valueColor: Theme.text

    spacing: 8
    Layout.fillWidth: true

    Txt {
        text: Theme.icon(parent.iconCode)
        color: Theme.muted
        font.pixelSize: 14
        Layout.preferredWidth: 18
    }
    Txt { text: parent.label; color: Theme.subtle; font.pixelSize: 12 }
    Item { Layout.fillWidth: true }
    Txt { text: parent.value; color: parent.valueColor; font.pixelSize: 12 }
}
