import QtQuick
import qs.services

// An on/off switch
Rectangle {
    id: t

    property bool checked: false
    signal toggled()

    implicitWidth: 36
    implicitHeight: 20
    radius: 10
    color: checked ? Theme.alpha(Theme.blue, 0.3) : Theme.overlay
    border.width: 1
    border.color: checked ? Theme.blue : Theme.alpha(Theme.muted, 0.6)
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        y: 3
        x: t.checked ? t.width - width - 3 : 3
        color: t.checked ? Theme.blue : Theme.subtle
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled()
    }
}
