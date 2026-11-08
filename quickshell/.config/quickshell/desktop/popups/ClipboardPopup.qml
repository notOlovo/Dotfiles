import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Clipboard history: search, image previews, copy and delete
Card {
    id: root
    title: I18n.t("clipboard", "буфер обмена")
    iconCode: 0xF014C
    width: 560
    color: Theme.alpha(Theme.base, 0.94)

    readonly property string script: Quickshell.shellDir + "/scripts/clipboard.sh"

    property var entries: []          // [{ id, kind, thumb, preview }]
    property bool loaded: false
    property bool confirmWipe: false

    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        return q ? entries.filter(e => e.preview.toLowerCase().includes(q)) : entries;
    }

    Process {
        running: true
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l).map(l => {
                    const [id, kind, thumb, ...rest] = l.split("\t");
                    return { id, kind, thumb, preview: rest.join("\t") };
                });
                root.loaded = true;
            }
        }
    }

    function copy(e) {
        Quickshell.execDetached([script, "copy", e.id]);
        Popups.close();
    }

    function remove(e) {
        Quickshell.execDetached([script, "delete", e.id]);
        entries = entries.filter(x => x.id !== e.id);
    }

    function wipe() {
        if (!confirmWipe) { confirmWipe = true; wipeTimer.restart(); return; }
        Quickshell.execDetached([script, "wipe"]);
        entries = [];
        confirmWipe = false;
    }

    Timer { id: wipeTimer; interval: 3000; onTriggered: root.confirmWipe = false }

    function kindIcon(k) { return k === "image" ? 0xF02E9 : k === "link" ? 0xF0337 : 0xF0284; }
    function kindLabel(k) { return k === "image" ? I18n.t("image", "картинка") : k === "link" ? I18n.t("link", "ссылка") : I18n.t("text", "текст"); }

    // ---------- Search + wipe ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Field {
            id: search
            Layout.fillWidth: true
            placeholder: I18n.t("search history…", "поиск по истории…")
            Component.onCompleted: input.forceActiveFocus()
            onTextChanged: list.currentIndex = 0

            onDownPressed: list.incrementCurrentIndex()
            onUpPressed: list.decrementCurrentIndex()
            onDeletePressed: if (list.currentItem) root.remove(list.currentItem.modelData)
            onAccepted: if (list.currentItem) root.copy(list.currentItem.modelData)
        }

        Rectangle {
            implicitWidth: wipeLabel.implicitWidth + 20
            implicitHeight: 36
            radius: 8
            color: root.confirmWipe ? Theme.alpha(Theme.rose, 0.18)
                 : wipeMa.containsMouse ? Theme.alpha(Theme.overlay, 0.8) : "transparent"
            border.width: 1
            border.color: root.confirmWipe ? Theme.rose : Theme.overlay
            visible: root.entries.length > 0

            Txt {
                id: wipeLabel
                anchors.centerIn: parent
                text: Theme.icon(0xF0A7A) + "  " + (root.confirmWipe ? I18n.t("sure?", "точно?") : I18n.t("clear", "очистить"))
                color: root.confirmWipe ? Theme.rose : Theme.subtle
                font.pixelSize: 12
            }
            MouseArea {
                id: wipeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wipe()
            }
        }
    }

    Txt {
        visible: root.loaded
        text: root.filtered.length === root.entries.length
              ? root.entries.length + " " + I18n.plural(root.entries.length, "entry", "entries", "запись", "записи", "записей")
              : I18n.t("found ", "найдено ") + root.filtered.length + I18n.t(" of ", " из ") + root.entries.length
        color: Theme.muted
        font.pixelSize: 11
    }

    // ---------- List ----------
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 440)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        populate: PopulateFx {}
        highlightMoveDuration: 0
        model: root.filtered

        delegate: Entry {
            id: row
            required property var modelData
            required property int index
            width: ListView.view.width
            selected: ListView.isCurrentItem
            onClicked: root.copy(modelData)

            Txt {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2
                text: Theme.icon(root.kindIcon(row.modelData.kind))
                font.pixelSize: 15
                color: row.modelData.kind === "link" ? Theme.cyan
                     : row.modelData.kind === "image" ? Theme.violet : Theme.subtle
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Image {
                    visible: row.modelData.kind === "image"
                    source: row.modelData.thumb ? "file://" + row.modelData.thumb : ""
                    Layout.preferredHeight: 90
                    Layout.preferredWidth: 160
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    sourceSize.height: 180
                }

                Txt {
                    Layout.fillWidth: true
                    text: row.modelData.preview
                    color: row.selected || row.hovered ? Theme.bright : Theme.text
                    font.pixelSize: row.modelData.kind === "image" ? 11 : 13
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            Txt {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 3
                visible: !(row.hovered || row.selected)
                text: root.kindLabel(row.modelData.kind)
                color: Theme.muted
                font.pixelSize: 10
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                visible: row.hovered || row.selected
                iconCode: 0xF0A7A
                font.pixelSize: 14
                onClicked: root.remove(row.modelData)
            }
        }
    }

    Txt {
        visible: root.loaded && root.filtered.length === 0
        text: root.entries.length ? I18n.t("nothing found", "ничего не найдено") : I18n.t("history is empty — copy something", "история пуста — скопируйте что-нибудь")
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        Layout.bottomMargin: 10
    }

    // ---------- Hint ----------
    Txt {
        Layout.alignment: Qt.AlignHCenter
        text: I18n.t("click / ↵ — copy   ·   ↑↓ — select   ·   Del — delete   ·   Esc — close", "клик / ↵ — скопировать   ·   ↑↓ — выбрать   ·   Del — удалить   ·   Esc — закрыть")
        color: Theme.muted
        font.pixelSize: 10
    }
}
