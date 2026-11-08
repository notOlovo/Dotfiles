pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The palette is read from waybar/colors.css — one source for the bar and the widgets.
// The file is watched: a change in colors.css recolors the widgets live.
Singleton {
    id: root

    property var c: ({})

    readonly property color voidColor: c.void    ?? "#05060b"
    readonly property color base:      c.base    ?? "#0a0c16"
    readonly property color surface:   c.surface ?? "#11142a"
    readonly property color overlay:   c.overlay ?? "#1a1e3a"
    readonly property color muted:     c.muted   ?? "#3b4270"
    readonly property color subtle:    c.subtle  ?? "#6c739e"
    readonly property color text:      c.text    ?? "#c6cbe8"
    readonly property color bright:    c.bright  ?? "#e8eaff"
    readonly property color blue:      c.blue    ?? "#5b8cff"
    readonly property color violet:    c.violet  ?? "#9d6bff"
    readonly property color cyan:      c.cyan    ?? "#4fc8ff"
    readonly property color rose:      c.rose    ?? "#ff5c8a"

    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int radius: 10

    function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a); }
    function icon(cp) { return String.fromCodePoint(cp); }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/waybar/colors.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const out = {};
            const re = /@define-color\s+([\w-]+)\s+(#[0-9a-fA-F]{6})/g;
            const t = text();
            let m;
            while ((m = re.exec(t)) !== null)
                out[m[1]] = m[2];
            root.c = out;
        }
    }
}
