// ==========================================
//  SDDM — the "Cosmos" login screen (Qt6)
//  Colors, background and language: theme.conf (rendered from the dotfiles palette)
//  Install/update: ~/dotfiles/sddm/install.sh
// ==========================================
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: c.voidColor

    // ---- Palette from theme.conf ----
    QtObject {
        id: c
        readonly property color voidColor: config.voidColor || "#05060b"
        readonly property color base:      config.base    || "#0a0c16"
        readonly property color surface:   config.surface || "#11142a"
        readonly property color overlay:   config.overlay || "#1a1e3a"
        readonly property color muted:     config.muted   || "#3b4270"
        readonly property color subtle:    config.subtle  || "#6c739e"
        readonly property color text:      config.text    || "#c6cbe8"
        readonly property color bright:    config.bright  || "#e8eaff"
        readonly property color blue:      config.blue    || "#5b8cff"
        readonly property color violet:    config.violet  || "#9d6bff"
        readonly property color cyan:      config.cyan    || "#4fc8ff"
        readonly property color rose:      config.rose    || "#ff5c8a"
        readonly property string font:     config.font    || "JetBrainsMono Nerd Font Propo"
        function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a); }
        function icon(cp) { return String.fromCodePoint(cp); }
    }

    // Language from theme.conf (language=en|ru, from settings.conf in dotfiles)
    readonly property bool ru: config.language === "ru"
    readonly property var loc: Qt.locale(ru ? "ru_RU" : "en_US")
    function t(en, ruText) { return ru ? ruText : en; }

    // ---- Users and sessions (SDDM models are read through invisible delegates) ----
    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)

    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
        }
    }
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item { required property string name }
    }

    // users.count in the expression — to re-evaluate once the delegates exist
    readonly property var user: users.count > 0 ? users.itemAt(userIndex) : null
    readonly property string userLogin: user ? user.name : userModel.lastUser
    readonly property string userTitle: user ? (user.realName || user.name) : userLogin
    readonly property string sessionName: sessions.count > 0 ? (sessions.itemAt(sessionIndex)?.name ?? "") : ""

    // ---- Login ----
    property bool checking: false
    property string error: ""
    property bool leaving: false

    function login() {
        if (checking) return;
        checking = true;
        error = "";
        sddm.login(userLogin, password.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.checking = false;
            root.error = root.t("wrong password", "неверный пароль");
            password.text = "";
            shake.restart();
        }
        function onLoginSucceeded() { root.leaving = true; }
    }

    // ---- Clock ----
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---- Background: the wallpaper, already blurred and dimmed on install (sync.sh) ----
    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }
    Rectangle { anchors.fill: parent; color: c.alpha(c.voidColor, 0.35) }

    // ---- All content: fades in on start, fades out on login ----
    Item {
        id: content
        anchors.fill: parent
        property real reveal: 0
        Component.onCompleted: revealAnim.start()
        NumberAnimation { id: revealAnim; target: content; property: "reveal"; from: 0; to: 1; duration: 900; easing.type: Easing.OutQuint }
        opacity: root.leaving ? 0 : Math.min(1, reveal * 1.5)
        Behavior on opacity { enabled: root.leaving; NumberAnimation { duration: 400; easing.type: Easing.InCubic } }

        // ---- Center ----
        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -40 + (1 - content.reveal) * 30
            spacing: 6

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: clockText.implicitWidth
                implicitHeight: clockText.implicitHeight

                // The glow is a separate layer behind: without effects the clock is still visible
                MultiEffect {
                    anchors.fill: clockText
                    source: clockText
                    shadowEnabled: true
                    shadowColor: c.blue
                    shadowBlur: 1.0
                    shadowOpacity: 0.6
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
                Text {
                    id: clockText
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: c.bright
                    font.family: c.font
                    font.pixelSize: 132
                    font.weight: Font.ExtraLight
                    font.letterSpacing: -3
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.now.toLocaleDateString(root.loc, "dddd, d MMMM")
                color: c.text
                font.family: c.font
                font.pixelSize: 20
                font.weight: Font.Light
            }

            Item { Layout.preferredHeight: 40 }

            // Avatar (if any) and name; arrows switch the user
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Text {
                    visible: users.count > 1
                    text: c.icon(0xF0141)
                    color: prevUser.containsMouse ? c.bright : c.muted
                    font.family: c.font
                    font.pixelSize: 18
                    MouseArea { id: prevUser; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true
                        onClicked: root.userIndex = (root.userIndex - 1 + users.count) % users.count }
                }

                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: c.surface
                    border.width: 1
                    border.color: c.alpha(c.blue, 0.6)
                    clip: true

                    Image {
                        id: avatar
                        anchors.fill: parent
                        anchors.margins: 2
                        source: root.user && root.user.icon ? (root.user.icon.startsWith("file:") ? root.user.icon : "file://" + root.user.icon) : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }
                    Rectangle { id: avatarMask; anchors.fill: avatar; radius: 30; visible: false; layer.enabled: true }
                    MultiEffect {
                        anchors.fill: avatar
                        source: avatar
                        maskEnabled: true
                        maskSource: avatarMask
                        visible: avatar.status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: avatar.status !== Image.Ready
                        text: root.userTitle.charAt(0).toUpperCase()
                        color: c.blue
                        font.family: c.font
                        font.pixelSize: 26
                    }
                }

                Text {
                    visible: users.count > 1
                    text: c.icon(0xF0142)
                    color: nextUser.containsMouse ? c.bright : c.muted
                    font.family: c.font
                    font.pixelSize: 18
                    MouseArea { id: nextUser; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true
                        onClicked: root.userIndex = (root.userIndex + 1) % users.count }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                text: root.userTitle
                color: c.subtle
                font.family: c.font
                font.pixelSize: 14
                font.letterSpacing: 2
            }

            // Password field
            Rectangle {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                implicitWidth: 320
                implicitHeight: 48
                radius: 24
                color: c.alpha(c.base, 0.75)
                border.width: 1
                border.color: root.error ? c.rose : password.activeFocus ? c.alpha(c.blue, 0.8) : c.overlay
                Behavior on border.color { ColorAnimation { duration: 150 } }

                property real dx: 0
                transform: Translate { x: field.dx }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: field; property: "dx"; to: -10; duration: 50 }
                    NumberAnimation { target: field; property: "dx"; to: 10; duration: 70 }
                    NumberAnimation { target: field; property: "dx"; to: -6; duration: 60 }
                    NumberAnimation { target: field; property: "dx"; to: 0; duration: 60 }
                }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    anchors.rightMargin: 52   // symmetric: the center matches the placeholder
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: c.bright
                    font.family: c.font
                    font.pixelSize: 18
                    cursorDelegate: Item {}   // custom cursor below
                    focus: true
                    enabled: !root.checking
                    onTextChanged: if (text) root.error = ""
                    onAccepted: root.login()
                    Component.onCompleted: forceActiveFocus()
                }

                Text {
                    id: hint
                    anchors.centerIn: parent
                    visible: password.text === ""
                    text: root.checking ? root.t("signing in…", "вход…") : root.t("password", "пароль")
                    color: c.muted
                    font.family: c.font
                    font.pixelSize: 14
                }

                // Cursor: before the placeholder when empty, after the last dot while typing
                Rectangle {
                    id: caret
                    width: 2
                    height: 20
                    radius: 1
                    color: c.blue
                    anchors.verticalCenter: parent.verticalCenter
                    x: password.text === "" ? hint.x - width - 6
                                          : password.x + password.cursorRectangle.x + 3
                    visible: password.activeFocus && !root.checking

                    // Blinks in pauses, steady while typing
                    SequentialAnimation on opacity {
                        id: blink
                        loops: Animation.Infinite
                        running: caret.visible
                        PropertyAction { value: 1 }
                        PauseAnimation { duration: 500 }
                        NumberAnimation { to: 0; duration: 350; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 350; easing.type: Easing.InOutSine }
                    }
                    Connections {
                        target: password
                        function onTextChanged() { blink.restart(); }
                    }
                }

                // Keyboard layout
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var layout: keyboard.layouts[keyboard.currentLayout]
                    text: layout ? layout.shortName.toUpperCase() : ""
                    color: c.muted
                    font.family: c.font
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                text: root.error
                color: c.rose
                font.family: c.font
                font.pixelSize: 12
                opacity: root.error ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // ---- Bottom left: session ----
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 40
            implicitWidth: sessionRow.implicitWidth + 28
            implicitHeight: 36
            radius: 18
            color: sessionMa.containsMouse ? c.alpha(c.overlay, 0.8) : c.alpha(c.base, 0.6)
            border.width: 1
            border.color: c.overlay
            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 8
                Text { text: c.icon(0xF0379); color: c.violet; font.family: c.font; font.pixelSize: 14 }   // monitor
                Text { text: root.sessionName; color: c.text; font.family: c.font; font.pixelSize: 12 }
                Text { visible: sessions.count > 1; text: c.icon(0xF0140); color: c.muted; font.family: c.font; font.pixelSize: 12 }
            }
            MouseArea {
                id: sessionMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessions.count
            }
        }

        // ---- Bottom right: power ----
        RowLayout {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 40
            spacing: 10

            Repeater {
                model: [
                    { cp: 0xF04B2, label: root.t("sleep", "сон"),               ok: sddm.canSuspend,  act: () => sddm.suspend() },
                    { cp: 0xF0709, label: root.t("reboot", "перезагрузка"),    ok: sddm.canReboot,   act: () => sddm.reboot() },
                    { cp: 0xF0425, label: root.t("shut down", "выключение"),   ok: sddm.canPowerOff, act: () => sddm.powerOff() }
                ]
                Rectangle {
                    id: pb
                    required property var modelData
                    visible: modelData.ok
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 20
                    color: pbMa.containsMouse ? c.alpha(modelData.cp === 0xF0425 ? c.rose : c.blue, 0.18) : c.alpha(c.base, 0.6)
                    border.width: 1
                    border.color: pbMa.containsMouse ? (modelData.cp === 0xF0425 ? c.rose : c.blue) : c.overlay
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: c.icon(pb.modelData.cp)
                        color: pbMa.containsMouse ? c.bright : c.subtle
                        font.family: c.font
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: pbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pb.modelData.act()
                    }
                }
            }
        }
    }
}
