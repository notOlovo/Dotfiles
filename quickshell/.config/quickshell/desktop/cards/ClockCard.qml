import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components

// Large clock right on the wallpaper, without a card
Column {
    id: root
    spacing: 4

    readonly property var loc: I18n.locale       // dates in the interface language
    readonly property int hour: clock.date.getHours()

    readonly property string greeting:
        hour >= 5 && hour < 12 ? I18n.t("good morning", "доброе утро") :
        hour >= 12 && hour < 18 ? I18n.t("good afternoon", "добрый день") :
        hour >= 18 && hour < 23 ? I18n.t("good evening", "добрый вечер") : I18n.t("good night", "доброй ночи")

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Smooth reveal (like the cards)
    property int revealDelay: -1
    property real revealShift: 0
    transform: Translate { y: root.revealShift }
    Component.onCompleted: if (revealDelay >= 0) reveal.start()
    SequentialAnimation {
        id: reveal
        PropertyAction { target: root; property: "opacity"; value: 0 }
        PropertyAction { target: root; property: "revealShift"; value: 22 }
        PauseAnimation { duration: Math.max(0, root.revealDelay) }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "revealShift"; to: 0; duration: 800; easing.type: Easing.OutQuint }
        }
    }

    Txt {
        id: time
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.bright
        font.pixelSize: 104
        font.weight: Font.ExtraLight
        font.letterSpacing: -2
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.blue
            // A soft wide glow instead of a dense outline
            blurMax: 64
            shadowBlur: 1.0
            shadowOpacity: 0.28
            shadowScale: 1.03
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }

    Txt {
        leftPadding: 6
        text: clock.date.toLocaleDateString(root.loc, "dddd, d MMMM")
        color: Theme.text
        font.pixelSize: 18
        font.weight: Font.Light
    }

    Txt {
        leftPadding: 6
        topPadding: 6
        text: root.greeting + ", " + (Quickshell.env("USER") ?? "")
        color: Theme.muted
        font.pixelSize: 13
        font.italic: true
    }

    // ---- ArchWiki article: left click — open in the browser, right click — next ----
    Item {
        visible: ArchWiki.ready
        width: 480
        height: wiki.implicitHeight

        Column {
            id: wiki
            leftPadding: 6
            topPadding: 22
            spacing: 6

            Row {
                spacing: 8
                Txt {
                    text: Theme.icon(0xF303)    // Arch logo
                    color: wikiMouse.containsMouse ? Theme.blue : Theme.violet
                    font.pixelSize: 14
                }
                Txt {
                    text: "arch wiki  ·  " + ArchWiki.shortTitle
                    color: wikiMouse.containsMouse ? Theme.bright : Theme.subtle
                    font.pixelSize: 12
                    font.letterSpacing: 1
                }
            }

            Txt {
                width: 470
                text: ArchWiki.extract
                color: wikiMouse.containsMouse ? Theme.text : Theme.subtle
                font.pixelSize: 13
                lineHeight: 1.25
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: wikiMouse
            anchors.fill: parent
            anchors.topMargin: 22
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: e => {
                if (e.button === Qt.RightButton) ArchWiki.next();
                else Qt.openUrlExternally(ArchWiki.url);
            }
        }
    }
}
