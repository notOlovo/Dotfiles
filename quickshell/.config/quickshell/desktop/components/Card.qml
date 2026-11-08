import QtQuick
import QtQuick.Layouts
import qs.services

// A translucent card: a title with an icon + content in a column
Rectangle {
    id: card

    property string title: ""
    property int iconCode: 0
    property int pad: 18
    default property alias content: body.data

    implicitWidth: col.implicitWidth + pad * 2
    implicitHeight: col.implicitHeight + pad * 2

    color: Theme.alpha(Theme.base, 0.72)
    radius: Theme.radius
    border.width: 1
    border.color: Theme.alpha(Theme.overlay, 0.9)

    // Smooth reveal on creation: >= 0 — delay in ms (desktop widgets)
    property int revealDelay: -1
    property real revealShift: 0
    transform: Translate { y: card.revealShift }
    Component.onCompleted: if (revealDelay >= 0) reveal.start()

    SequentialAnimation {
        id: reveal
        PropertyAction { target: card; property: "opacity"; value: 0 }
        PropertyAction { target: card; property: "revealShift"; value: 22 }
        PauseAnimation { duration: Math.max(0, card.revealDelay) }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "revealShift"; to: 0; duration: 700; easing.type: Easing.OutQuint }
        }
    }

    // A click on a card doesn't close the overlay
    MouseArea { anchors.fill: parent }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: 14

        RowLayout {
            visible: card.title !== ""
            spacing: 8
            Txt {
                visible: card.iconCode > 0
                text: Theme.icon(card.iconCode)
                color: Theme.violet
                font.pixelSize: 14
            }
            Txt {
                text: card.title.toUpperCase()
                color: Theme.subtle
                font.pixelSize: 11
                font.letterSpacing: 2
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
