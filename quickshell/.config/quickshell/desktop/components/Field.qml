import QtQuick
import qs.services

// A themed text field
Rectangle {
    id: f

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false
    signal accepted()
    signal upPressed()
    signal downPressed()
    signal deletePressed()      // Del at the end of the text — for list actions
    signal leftPressed()        // ←/→ with an empty field — for grid navigation
    signal rightPressed()
    signal tabPressed()

    implicitHeight: 36
    radius: 8
    color: Theme.surface
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.blue, 0.7) : Theme.overlay

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.bright
        selectionColor: Theme.alpha(Theme.blue, 0.4)
        font.family: Theme.font
        font.pixelSize: 13
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        clip: true
        onAccepted: f.accepted()
        Keys.onUpPressed: f.upPressed()
        Keys.onDownPressed: f.downPressed()
        Keys.onLeftPressed: e => { if (text === "") f.leftPressed(); else e.accepted = false; }
        Keys.onRightPressed: e => { if (text === "") f.rightPressed(); else e.accepted = false; }
        Keys.onTabPressed: f.tabPressed()
        Keys.onDeletePressed: e => {
            if (cursorPosition === text.length) f.deletePressed();
            else e.accepted = false;
        }
    }

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        x: 12
        visible: input.text === ""
        text: f.placeholder
        color: Theme.muted
    }
}
