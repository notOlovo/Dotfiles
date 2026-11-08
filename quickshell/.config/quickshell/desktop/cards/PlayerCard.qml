import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.services
import qs.components

// Now playing. The card is visible only when there is a player.
Card {
    id: card

    readonly property var player: {
        // playerctld is a proxy over other players — skip it
        const ps = Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"));
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }

    visible: player !== null
    pad: 14

    function fmt(s) {
        if (!isFinite(s) || s < 0) return "0:00";
        const m = Math.floor(s / 60), r = Math.floor(s % 60);
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    // The track position doesn't update by itself — ask once a second
    Timer {
        running: card.visible && (card.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: card.player.positionChanged()
    }

    RowLayout {
        spacing: 14
        Layout.fillWidth: true

        ClippingRectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 8
            color: Theme.surface

            Image {
                anchors.fill: parent
                source: card.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
            }
            Txt {
                anchors.centerIn: parent
                visible: !(card.player?.trackArtUrl)
                text: Theme.icon(0xF075A)
                color: Theme.muted
                font.pixelSize: 26
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Txt {
                Layout.fillWidth: true
                text: card.player?.trackTitle || I18n.t("untitled", "без названия")
                color: Theme.bright
                font.pixelSize: 14
                elide: Text.ElideRight
            }
            Txt {
                Layout.fillWidth: true
                text: card.player?.trackArtist || card.player?.identity || ""
                color: Theme.subtle
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.topMargin: 4
                spacing: 18
                Repeater {
                    model: [
                        { cp: 0xF04AE, act: () => card.player.previous(), ok: card.player?.canGoPrevious },
                        { cp: card.player?.isPlaying ? 0xF03E4 : 0xF040A, act: () => card.player.togglePlaying(), ok: true },
                        { cp: 0xF04AD, act: () => card.player.next(), ok: card.player?.canGoNext }
                    ]
                    Txt {
                        required property var modelData
                        text: Theme.icon(modelData.cp)
                        font.pixelSize: 18
                        color: !modelData.ok ? Theme.muted : ma.containsMouse ? Theme.blue : Theme.text
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            onClicked: if (parent.modelData.ok) parent.modelData.act()
                        }
                    }
                }
            }
        }
    }

    // Progress
    ColumnLayout {
        visible: (card.player?.length ?? 0) > 0
        Layout.fillWidth: true
        spacing: 4
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 2
            color: Theme.overlay
            Rectangle {
                width: parent.width * Math.min(1, (card.player?.position ?? 0) / Math.max(1, card.player?.length ?? 1))
                height: parent.height
                radius: 2
                color: Theme.cyan
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Txt { text: card.fmt(card.player?.position ?? 0); color: Theme.muted; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Txt { text: card.fmt(card.player?.length ?? 0); color: Theme.muted; font.pixelSize: 10 }
        }
    }
}
