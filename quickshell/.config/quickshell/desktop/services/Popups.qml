pragma Singleton
import QtQuick
import Quickshell

// Which popup is open: "", "audio", "network", "bluetooth", "clipboard", "keys", "launcher"
Singleton {
    id: root

    property string current: ""

    function toggle(name) { current = current === name ? "" : name; }
    function close() { current = ""; }

    // Run an external program and close the menu
    function launch(cmd) {
        Quickshell.execDetached(cmd);
        close();
    }
}
