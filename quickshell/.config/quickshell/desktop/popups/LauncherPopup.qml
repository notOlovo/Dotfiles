import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components

// Launcher (Win + A):
//   empty   — grid of frequent apps and open windows
//   text    — apps (fuzzy search) and windows
//   >text   — commands: lock, reboot, palette gruvbox, language ru, …
Card {
    id: root
    title: ""
    width: 640
    pad: 16
    color: Theme.alpha(Theme.base, 0.95)

    readonly property string query: search.text.trim()
    readonly property bool commandMode: query.startsWith(">")
    readonly property bool gridMode: query === ""
    readonly property int columns: 6

    property int current: 0

    // The mouse is ignored until it actually moves: a menu opened under the cursor
    // doesn't steal the selection. Typing and arrow keys put it back to sleep.
    property bool mouseActive: false
    onQueryChanged: mouseActive = false
    HoverHandler {
        property point last: Qt.point(-1, -1)
        onPointChanged: {
            const p = point.position;
            if (last.x >= 0 && Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2)
                root.mouseActive = true;
            last = p;
        }
    }
    property string confirm: ""        // command waiting for a second Enter

    // ---------- Launch frequency ----------
    property var usage: ({})           // id → { n, last }
    FileView {
        id: usageFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/launcher.json"
        printErrors: false
        onLoaded: { try { root.usage = JSON.parse(text()); } catch (e) {} }
    }

    function frecency(id) {
        const u = usage[id];
        if (!u) return 0;
        const days = (Date.now() - u.last) / 86400000;
        return u.n * (days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5);
    }

    function remember(id) {
        const u = Object.assign({}, usage);
        u[id] = { n: (u[id]?.n ?? 0) + 1, last: Date.now() };
        usage = u;
        Quickshell.execDetached(["mkdir", "-p", usageFile.path.replace(/\/[^/]+$/, "")]);
        usageFile.setText(JSON.stringify(u));
    }

    // ---------- Sources ----------
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var windows: ToplevelManager.toplevels.values.filter(t => t.appId !== "" )

    // Fuzzy match: 0 — no match, higher is better
    function score(text, q) {
        if (!text) return 0;
        const t = text.toLowerCase();
        if (t === q) return 100;
        if (t.startsWith(q)) return 80;
        if (t.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 60;
        if (t.includes(q)) return 40;
        let i = 0;
        for (const ch of t) if (ch === q[i]) i++;
        return i === q.length ? 15 : 0;
    }

    function appScore(a, q) {
        const s = Math.max(score(a.name, q),
                           score(a.genericName, q) * 0.7,
                           (a.keywords ?? []).reduce((m, k) => Math.max(m, score(k, q) * 0.6), 0),
                           score(a.comment, q) * 0.4);
        return s > 0 ? s + Math.min(20, frecency(a.id)) : 0;
    }

    function appIcon(name) { return Quickshell.iconPath(name ?? "", "application-x-executable"); }

    // ---------- Commands ----------
    function palettes() { return ["cosmos", "gruvbox", "monochrome", "catppuccin", "wallpaper"]; }

    // Search words in both languages, so >lock and >блок work either way
    readonly property var commands: [
        { words: ["lock", "блок"],              name: I18n.t("Lock screen", "Заблокировать экран"), icon: 0xF033E, cmd: ["loginctl", "lock-session"] },
        { words: ["suspend", "sleep", "сон"],   name: I18n.t("Sleep", "Сон"),                       icon: 0xF04B2, cmd: ["systemctl", "suspend"] },
        { words: ["logout", "exit", "выйти"],   name: I18n.t("Log out", "Выйти из сессии"),         icon: 0xF0343, cmd: ["hyprctl", "dispatch", "exit"], danger: true },
        { words: ["reboot", "перезагрузка"],    name: I18n.t("Reboot", "Перезагрузка"),            icon: 0xF0709, cmd: ["systemctl", "reboot"], danger: true },
        { words: ["shutdown", "poweroff", "выключить"], name: I18n.t("Shut down", "Выключение"),   icon: 0xF0425, cmd: ["systemctl", "poweroff"], danger: true },
        { words: ["wallpaper", "обои"],         name: I18n.t("Change wallpaper", "Сменить обои"),   icon: 0xF0E09, cmd: [Quickshell.env("HOME") + "/.config/theme/menu.sh", "wallpaper"] },
        { words: ["keys", "клавиши"],           name: I18n.t("Keybind cheatsheet", "Шпаргалка по клавишам"), icon: 0xF030C, popup: "keys" },
        { words: ["clipboard", "буфер"],        name: I18n.t("Clipboard", "Буфер обмена"),          icon: 0xF014C, popup: "clipboard" },
        { words: ["language en", "язык en", "english"], name: "Interface language: English",      icon: 0xF05CA, cmd: [Quickshell.env("HOME") + "/.config/theme/theme.py", "language", "en"] },
        { words: ["language ru", "язык ru", "русский"], name: "Язык интерфейса: русский",         icon: 0xF05CA, cmd: [Quickshell.env("HOME") + "/.config/theme/theme.py", "language", "ru"] }
    ].concat(palettes().map(p => ({
        words: ["palette " + p, "палитра " + p, "theme " + p],
        name: I18n.t("Palette: ", "Палитра: ") + (p === "wallpaper" ? I18n.t("from wallpaper", "из обоев") : p[0].toUpperCase() + p.slice(1)),
        icon: 0xF03D8,
        cmd: p === "wallpaper"
            ? ["sh", "-c", "w=$(awk -F' = ' '/^wallpaper/{print $2}' ~/.config/waypaper/config.ini); ~/.config/theme/theme.py wallpaper \"${w/#\\~/$HOME}\""]
            : [Quickshell.env("HOME") + "/.config/theme/theme.py", "apply", p]
    })))

    // ---------- Result list ----------
    // Each item: { kind: app|window|command, title, sub, icon / glyph, run() }
    readonly property var items: {
        const q = query.toLowerCase();

        if (commandMode) {
            const c = q.slice(1).trim();
            return commands
                .filter(k => !c || k.words.some(w => w.startsWith(c) || c.startsWith(w.split(" ")[0]) && w.includes(c)))
                .map(k => ({ kind: "command", title: k.name, sub: ">" + k.words[0], glyph: k.icon, data: k }));
        }

        if (gridMode) {
            // While there are few stats — main apps first, system settings last
            const fav = ["kitty", "firefox", "code", "thunar", "org.telegram.desktop", "obsidian",
                         "spotify", "discord", "steam", "btop", "org.pulseaudio.pavucontrol", "nvim"];
            const rank = a => {
                const i = Math.max(fav.indexOf(a.id), fav.indexOf(a.id.replace(/\.desktop$/, "")));
                const system = (a.categories ?? []).some(c => c === "Settings" || c === "System");
                return frecency(a.id) * 100 + (i >= 0 ? fav.length - i : system ? -50 : 0);
            };
            const top = apps.slice()
                .sort((a, b) => rank(b) - rank(a) || a.name.localeCompare(b.name))
                .slice(0, columns * 2);
            return top.map(a => ({ kind: "app", title: a.name, icon: a.icon, data: a }))
                .concat(windows.slice(0, 5).map(t => ({ kind: "window", title: t.title, sub: t.appId,
                         icon: DesktopEntries.heuristicLookup(t.appId)?.icon ?? t.appId, data: t })));
        }

        const found = apps.map(a => ({ a, s: appScore(a, q) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s)
            .slice(0, 8)
            .map(x => ({ kind: "app", title: x.a.name, sub: x.a.genericName || x.a.comment || "", icon: x.a.icon, data: x.a }));

        const wins = windows
            .map(t => ({ t, s: Math.max(score(t.title, q), score(t.appId, q)) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s)
            .slice(0, 4)
            .map(x => ({ kind: "window", title: x.t.title, sub: x.t.appId,
                         icon: DesktopEntries.heuristicLookup(x.t.appId)?.icon ?? x.t.appId, data: x.t }));

        return found.concat(wins);
    }

    readonly property int gridCount: gridMode ? Math.min(columns * 2, items.filter(i => i.kind === "app").length) : 0

    onItemsChanged: { current = 0; confirm = ""; }

    function run(item) {
        if (!item) return;
        if (item.kind === "app") {
            remember(item.data.id);
            // Telegram lives in the tray and its window in the hidden special:telegram:
            // launching it again shows nothing, so open the dropdown window (Win+G)
            if (/telegram/i.test(item.data.id)) Popups.launch([Quickshell.env("HOME") + "/.config/hypr/scripts/telegram.sh", "show"]);
            else { item.data.execute(); Popups.close(); }
        } else if (item.kind === "window") {
            item.data.activate();
            Popups.close();
        } else if (item.kind === "command") {
            const k = item.data;
            if (k.danger && confirm !== k.name) { confirm = k.name; return; }
            if (k.popup) { Popups.toggle(k.popup); return; }
            Popups.launch(k.cmd);
        }
    }

    function move(d) {
        const n = items.length;
        mouseActive = false;
        if (n) current = (current + d + n) % n;
    }

    // ---------- Search field ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Txt {
            text: Theme.icon(root.commandMode ? 0xF018D : 0xF0349)     // console / magnify
            color: root.commandMode ? Theme.violet : Theme.blue
            font.pixelSize: 20
        }

        Field {
            id: search
            Layout.fillWidth: true
            implicitHeight: 42
            placeholder: I18n.t("app, window or >command", "приложение, окно или >команда")
            color: "transparent"
            border.width: 0
            input.font.pixelSize: 16
            Component.onCompleted: input.forceActiveFocus()

            onAccepted: root.run(root.items[root.current])
            onTabPressed: root.move(1)
            onDownPressed: root.move(root.gridMode && root.current < root.gridCount ? root.columns : 1)
            onUpPressed: root.move(root.gridMode && root.current < root.gridCount ? -root.columns : -1)
            onLeftPressed: root.move(-1)
            onRightPressed: root.move(1)
        }
    }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

    // ---------- Empty: grid of frequent apps ----------
    GridLayout {
        visible: root.gridMode
        Layout.fillWidth: true
        columns: root.columns
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.gridMode ? root.items.slice(0, root.gridCount) : []

            Rectangle {
                id: cell
                required property var modelData
                required property int index
                readonly property bool sel: root.current === index
                readonly property bool hot: root.mouseActive && cellMa.containsMouse
                onHotChanged: if (hot) root.current = index
                Layout.fillWidth: true
                implicitHeight: 92
                radius: 10
                color: sel ? Theme.alpha(Theme.blue, 0.14) : cell.hot ? Theme.alpha(Theme.overlay, 0.8) : "transparent"
                border.width: sel ? 1 : 0
                border.color: Theme.alpha(Theme.blue, 0.5)
                Behavior on color { ColorAnimation { duration: 140 } }

                // The selected icon is slightly larger
                scale: sel ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

                // Cascading grid reveal
                opacity: 0
                Component.onCompleted: appear.start()
                SequentialAnimation {
                    id: appear
                    PauseAnimation { duration: 40 + cell.index * 22 }
                    NumberAnimation { target: cell; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    spacing: 6
                    IconImage {
                        Layout.alignment: Qt.AlignHCenter
                        implicitSize: 40
                        source: root.appIcon(cell.modelData.icon)
                    }
                    Txt {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.title
                        color: cell.sel ? Theme.bright : Theme.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(cell.modelData)
                }
            }
        }
    }

    // ---------- List: results / windows ----------
    Section {
        visible: list.count > 0 && (root.gridMode || root.commandMode || root.items.some(i => i.kind === "window"))
        text: root.commandMode ? I18n.t("COMMANDS", "КОМАНДЫ") : root.gridMode ? I18n.t("OPEN WINDOWS", "ОТКРЫТЫЕ ОКНА") : I18n.t("RESULTS", "РЕЗУЛЬТАТЫ")
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 420)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        populate: PopulateFx {}
        interactive: contentHeight > height
        model: root.items.slice(root.gridCount)

        delegate: Entry {
            id: row
            required property var modelData
            required property int index
            readonly property int globalIndex: index + root.gridCount
            width: ListView.view.width
            selected: root.current === globalIndex
            hoverable: root.mouseActive
            onClicked: root.run(modelData)
            onHoveredChanged: if (hovered) root.current = globalIndex

            Item {
                implicitWidth: 26
                implicitHeight: 26
                IconImage {
                    anchors.centerIn: parent
                    visible: row.modelData.kind !== "command"
                    implicitSize: 24
                    source: row.modelData.kind !== "command" ? root.appIcon(row.modelData.icon) : ""
                }
                Txt {
                    anchors.centerIn: parent
                    visible: row.modelData.kind === "command"
                    text: Theme.icon(row.modelData.glyph ?? 0)
                    color: row.modelData.data?.danger ? Theme.rose : Theme.violet
                    font.pixelSize: 18
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt {
                    Layout.fillWidth: true
                    text: row.modelData.title
                    color: row.selected ? Theme.bright : Theme.text
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                Txt {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: row.modelData.sub ?? ""
                    color: Theme.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Txt {
                text: root.confirm === row.modelData.title ? I18n.t("Enter again to confirm", "Enter ещё раз — подтвердить")
                    : row.modelData.kind === "window" ? I18n.t("window", "окно")
                    : row.selected ? "↵" : ""
                color: root.confirm === row.modelData.title ? Theme.rose : Theme.muted
                font.pixelSize: 11
            }
        }

        onCountChanged: positionViewAtBeginning()
    }

    Connections {
        target: root
        function onCurrentChanged() {
            if (root.current >= root.gridCount) list.positionViewAtIndex(root.current - root.gridCount, ListView.Contain);
        }
    }

    Txt {
        visible: root.items.length === 0
        text: root.commandMode ? I18n.t("no such command", "нет такой команды") : I18n.t("nothing found", "ничего не найдено")
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        Layout.bottomMargin: 8
    }

    // ---------- Hint ----------
    Txt {
        Layout.alignment: Qt.AlignHCenter
        text: root.commandMode
            ? I18n.t("lock · suspend · logout · reboot · shutdown · wallpaper · palette <name> · language en|ru · keys · clipboard", "lock · suspend · logout · reboot · shutdown · wallpaper · palette <имя> · language en|ru · keys · clipboard")
            : I18n.t("↑↓←→ — select   ·   ↵ — run   ·   > — commands   ·   Esc — close", "↑↓←→ — выбор   ·   ↵ — запустить   ·   > — команды   ·   Esc — закрыть")
        color: Theme.muted
        font.pixelSize: 10
    }
}
