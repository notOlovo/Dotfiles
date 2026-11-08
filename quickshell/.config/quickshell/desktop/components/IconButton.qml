import QtQuick
import qs.services

// An icon button
Txt {
    id: b

    property int iconCode: 0
    property bool active: false
    property color activeColor: Theme.blue
    signal clicked()

    text: Theme.icon(iconCode)
    font.pixelSize: 16
    color: ma.containsMouse ? Theme.bright : active ? activeColor : Theme.subtle

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
