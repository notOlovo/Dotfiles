import QtQuick
import qs.services

// A 0..1 slider: drag, click, wheel
Item {
    id: s

    property real value: 0
    property color color: Theme.blue
    signal moved(real value)

    implicitHeight: 18

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.overlay

        Rectangle {
            width: parent.width * s.clamp(s.value)
            height: parent.height
            radius: 2
            color: s.color
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (s.width - width) * s.clamp(s.value)
        width: 12
        height: 12
        radius: 6
        color: Theme.bright
        opacity: ma.containsMouse || ma.pressed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: e => s.moved(s.clamp(e.x / width))
        onPositionChanged: e => { if (pressed) s.moved(s.clamp(e.x / width)); }
        onWheel: w => s.moved(s.clamp(s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
