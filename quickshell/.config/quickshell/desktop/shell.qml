// ==========================================
//  QUICKSHELL — desktop widgets
//  Run:      qs -c desktop
//  Overlay:  qs ipc -c desktop call desktop toggle   (Win+D)
//  Menus:    qs ipc -c desktop call popup toggle audio|network|bluetooth|clipboard|keys|launcher
// ==========================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.popups

ShellRoot {
    id: shell

    property bool overlay: false
    // The overlay window lives while the fade-out plays
    property bool overlayAlive: false
    onOverlayChanged: if (overlay) overlayAlive = true

    IpcHandler {
        target: "desktop"
        function toggle(): void { shell.overlay = !shell.overlay; }
        function open(): void  { shell.overlay = true; }
        function close(): void { shell.overlay = false; }
    }

    // The app list is read lazily — start right away so the launcher opens filled
    Component.onCompleted: DesktopEntries.applications

    // Volume and brightness indicator
    Osd {}

    // Low battery warnings
    BatteryWatch {}

    IpcHandler {
        target: "popup"
        function toggle(name: string): void { Popups.toggle(name); }
        function close(): void { Popups.close(); }
    }

    // ---- Popups from Waybar (on the active monitor) ----
    // shownPopup outlives Popups.current — while the closing animation plays
    property string shownPopup: ""

    Connections {
        target: Popups
        function onCurrentChanged() {
            if (Popups.current !== "") shell.shownPopup = Popups.current;
        }
    }

    LazyLoader {
        active: shell.shownPopup !== ""

        PanelWindow {
            id: popupWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-popup"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            readonly property bool open: Popups.current !== ""
            readonly property bool centered: ["clipboard", "keys", "launcher"].includes(shell.shownPopup)

            // Centered popups slightly dim the screen
            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.voidColor, 0.35)
                visible: popupWindow.centered
                opacity: stage.opacity
            }

            // A click outside the menu (including on Waybar) closes it
            MouseArea {
                anchors.fill: parent
                onClicked: Popups.close()
            }

            FocusScope {
                id: stage
                focus: true
                Keys.onEscapePressed: Popups.close()

                // Bar menus go under it on the right, the rest in the center
                x: popupWindow.centered ? (parent.width - width) / 2 : parent.width - width - 10
                y: popupWindow.centered ? 90 : 46
                width: popup.width
                height: popup.height

                transformOrigin: popupWindow.centered ? Item.Top : Item.TopRight
                property real shift: 0
                transform: Translate { y: stage.shift }

                opacity: 0
                scale: 0.94

                Loader {
                    id: popup
                    focus: true
                    sourceComponent: ({
                        audio: audioPopup,
                        network: networkPopup,
                        bluetooth: bluetoothPopup,
                        clipboard: clipboardPopup,
                        keys: keysPopup,
                        launcher: launcherPopup
                    })[shell.shownPopup] ?? null
                    onLoaded: { closeAnim.stop(); openAnim.restart(); }
                }

                ParallelAnimation {
                    id: openAnim
                    NumberAnimation { target: stage; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: stage; property: "scale"; from: 0.94; to: 1; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    NumberAnimation { target: stage; property: "shift"; from: -10; to: 0; duration: 340; easing.type: Easing.OutQuint }
                }

                ParallelAnimation {
                    id: closeAnim
                    NumberAnimation { target: stage; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
                    NumberAnimation { target: stage; property: "scale"; to: 0.96; duration: 140; easing.type: Easing.InCubic }
                    NumberAnimation { target: stage; property: "shift"; to: -6; duration: 140; easing.type: Easing.InCubic }
                    onFinished: if (Popups.current === "") shell.shownPopup = ""
                }

                Connections {
                    target: popupWindow
                    function onOpenChanged() { if (!popupWindow.open) { openAnim.stop(); closeAnim.restart(); } }
                }
            }

            Component { id: audioPopup;     AudioPopup {} }
            Component { id: networkPopup;   NetworkPopup {} }
            Component { id: bluetoothPopup; BluetoothPopup {} }
            Component { id: clipboardPopup; ClipboardPopup {} }
            Component { id: keysPopup;      KeysPopup {} }
            Component { id: launcherPopup;  LauncherPopup {} }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scr
            required property var modelData

            // On the wallpaper, under the windows. The Bottom layer, not Background:
            // swaybg recreates its surface on Background when the wallpaper changes
            // and it would land on top of the widgets.
            PanelWindow {
                screen: scr.modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "qs-desktop"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                Dashboard {
                    anchors.fill: parent
                    opacity: shell.overlay ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            // Above everything — created only while open
            LazyLoader {
                active: shell.overlayAlive

                PanelWindow {
                    screen: scr.modelData
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "qs-desktop-overlay"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                    exclusionMode: ExclusionMode.Ignore
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"

                    Item {
                        id: overlayRoot
                        anchors.fill: parent
                        opacity: 0
                        Component.onCompleted: fadeIn.start()

                        NumberAnimation { id: fadeIn; target: overlayRoot; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation {
                            id: fadeOut; target: overlayRoot; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic
                            onFinished: if (!shell.overlay) shell.overlayAlive = false
                        }
                        Connections {
                            target: shell
                            function onOverlayChanged() { if (!shell.overlay) { fadeIn.stop(); fadeOut.start(); } }
                        }

                        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.voidColor, 0.45) }

                        // A click outside the cards or Esc closes it
                        MouseArea {
                            anchors.fill: parent
                            onClicked: shell.overlay = false
                        }

                        Dashboard {
                            anchors.fill: parent
                            focus: true
                            Keys.onEscapePressed: shell.overlay = false
                        }
                    }
                }
            }
        }
    }
}
