import QtQuick
import QtQuick.Layouts
import qs.services

// A list row: highlight on hover, a border on the active one
Rectangle {
    id: e

    default property alias content: row.data
    property bool active: false
    property bool selected: false
    property bool hoverable: true      // false — hover doesn't highlight (the mouse is "asleep")
    readonly property bool hovered: hoverable && ma.containsMouse
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(36, row.implicitHeight + 14)
    radius: 8
    color: active ? Theme.alpha(Theme.blue, 0.12)
         : (hovered || selected) ? Theme.alpha(Theme.overlay, 0.8) : "transparent"
    border.width: active || selected ? 1 : 0
    border.color: active ? Theme.alpha(Theme.blue, 0.5) : Theme.alpha(Theme.muted, 0.5)
    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: e.clicked()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10
    }
}
