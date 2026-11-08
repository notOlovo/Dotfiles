import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Keybind cheatsheet. Source: ~/.config/hypr/keybinds.conf —
// the comment above a group of binds becomes its description ("# English | Русский").
Card {
    id: root
    title: I18n.t("keybinds", "горячие клавиши")
    iconCode: 0xF030C
    width: 920
    color: Theme.alpha(Theme.base, 0.95)

    // [{ title, mods: [...] | null, keys: [...], combos: [...] }] — re-parsed when the language changes
    property string source: ""
    readonly property var groups: source ? parse(source) : []

    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        if (!q) return groups;
        return groups.filter(g => (g.title + " " + g.combos.map(c => c.join(" ")).join(" ")).toLowerCase().includes(q));
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/keybinds.conf"
        onLoaded: root.source = text()
    }

    readonly property var modNames: ({ "$mainMod": "Win", "SUPER": "Win", "SHIFT": "Shift", "CTRL": "Ctrl", "CONTROL": "Ctrl", "ALT": "Alt" })
    readonly property var keyNames: ({
        left: "←", right: "→", up: "↑", down: "↓", slash: "/", Print: "PrtSc", Tab: "Tab",
        "mouse:272": I18n.t("LMB", "ЛКМ"), "mouse:273": I18n.t("RMB", "ПКМ"),
        mouse_down: I18n.t("wheel ↓", "колесо ↓"), mouse_up: I18n.t("wheel ↑", "колесо ↑"),
        XF86AudioRaiseVolume: I18n.t("Vol +", "Громк +"), XF86AudioLowerVolume: I18n.t("Vol −", "Громк −"),
        XF86AudioMute: I18n.t("Mute", "Без звука"), XF86AudioMicMute: I18n.t("Mic", "Микрофон"),
        XF86MonBrightnessUp: I18n.t("Bright +", "Ярк +"), XF86MonBrightnessDown: I18n.t("Bright −", "Ярк −"),
        XF86AudioPlay: "Play", XF86AudioNext: "Next", XF86AudioPrev: "Prev"
    })

    // Readable names for single actions (by dispatcher and command)
    function actionName(dispatcher, arg) {
        const exec = [
            [/\$terminal/, I18n.t("Terminal", "Терминал")], [/\$fileManager/, I18n.t("File manager", "Файловый менеджер")],
            [/\$menu/, I18n.t("App launcher", "Меню приложений")], [/\$browser/, I18n.t("Browser", "Браузер")],
            [/rotate\.sh/, I18n.t("Rotate screen", "Повернуть экран")], [/\$clipboard/, I18n.t("Clipboard", "Буфер обмена")],
            [/\$telegram/, "Telegram"], [/grim -g/, I18n.t("Screenshot of an area", "Скриншот области")],
            [/grim -/, I18n.t("Screenshot to clipboard", "Скриншот экрана в буфер")],
            [/snap\.sh left/, I18n.t("Window — left half", "Окно — левая половина")],
            [/snap\.sh right/, I18n.t("Window — right half", "Окно — правая половина")],
            [/snap\.sh max/, I18n.t("Maximize floating window", "Развернуть свободное окно")],
            [/snap\.sh tile/, I18n.t("Back to tiling", "Вернуть окно в плитки")]
        ];
        if (dispatcher === "exec") {
            for (const [re, name] of exec) if (re.test(arg)) return name;
            return null;
        }
        const names = {
            killactive: I18n.t("Close window", "Закрыть окно"), exit: I18n.t("Exit Hyprland", "Выйти из Hyprland"),
            togglefloating: I18n.t("Floating window", "Плавающее окно"),
            centerwindow: I18n.t("Center window", "Окно по центру"), pin: I18n.t("Pin on all workspaces", "Закрепить поверх всех столов"),
            cyclenext: I18n.t("Next window", "Следующее окно"), bringactivetotop: null,
            movewindow: I18n.t("Move window with mouse", "Двигать окно мышью"),
            resizewindow: I18n.t("Resize window with mouse", "Размер окна мышью")
        };
        if (dispatcher === "fullscreen") return arg === "1" ? I18n.t("Maximize (keep bar)", "Развернуть (с панелью)") : I18n.t("Fullscreen", "Полный экран");
        if (dispatcher === "workspace" && arg === "previous") return I18n.t("Previous workspace", "Предыдущий рабочий стол");
        if (dispatcher === "workspace" && /^e[+-]/.test(arg)) return I18n.t("Scroll workspaces", "Листать рабочие столы");
        return names[dispatcher] ?? null;
    }

    // "English | Русский" → the half for the current language, without (…) and details after ":" or ". "
    function cleanComment(c) {
        const halves = c.split(" | ");
        c = I18n.ru && halves.length > 1 ? halves[1] : halves[0];
        return c.replace(/\s*\([^)]*\)/g, "").split(/:|\.\s/)[0].trim();
    }

    function parse(text) {
        const raw = [];               // groups as in the file: { comment, binds: [{ combo, name }] }
        let comment = "", group = null, inHeader = false, skipNext = false;

        for (const line of text.split("\n")) {
            const t = line.trim();

            if (t === "") { group = null; comment = ""; skipNext = false; continue; }
            if (/^#\s*=+\s*$/.test(t)) { inHeader = !inHeader; continue; }        // file header
            if (inHeader) continue;
            if (/^#\s*-{3,}\s*$/.test(t)) { skipNext = !skipNext; group = null; continue; }   // section frame
            if (/^#\s*-{3,}/.test(t)) { group = null; comment = ""; continue; }  // "# ---- Section ----"
            if (t.startsWith("#")) {
                if (!skipNext) comment = cleanComment(t.replace(/^#\s*/, ""));
                group = null;
                continue;
            }

            const m = t.match(/^bind\w*\s*=\s*(.*)$/);
            if (!m) continue;
            const parts = m[1].split(",").map(x => x.trim());
            const mods = parts[0].split(/\s+/).filter(x => x).map(x => modNames[x] ?? x);
            const combo = mods.concat([keyNames[parts[1]] ?? parts[1]]);
            const name = actionName(parts[2], parts.slice(3).join(","));
            if (name === undefined || (name === null && parts[2] === "bringactivetotop")) continue;

            if (!group) { group = { comment, binds: [] }; raw.push(group); }
            if (!group.binds.some(b => b.combo.join("+") === combo.join("+")))
                group.binds.push({ combo, name });
        }

        // A group with different actions → one row per action
        const rows = [];
        for (const g of raw) {
            const names = g.binds.map(b => b.name);
            const distinct = new Set(names);
            if (g.binds.length > 1 && names.every(n => n) && distinct.size > 1) {
                for (const b of g.binds) rows.push({ title: b.name, combos: [b.combo] });
            } else {
                rows.push({ title: g.comment || names[0] || "—", combos: g.binds.map(b => b.combo) });
            }
        }

        // Merge adjacent rows with the same title
        for (let i = rows.length - 1; i > 0; i--) {
            if (rows[i].title === rows[i - 1].title) {
                rows[i - 1].combos = rows[i - 1].combos.concat(rows[i].combos);
                rows.splice(i, 1);
            }
        }

        // Same modifiers → "Win + Shift" once, then the list of keys
        for (const r of rows) {
            const m0 = r.combos[0].slice(0, -1).join("+");
            const same = r.combos.every(c => c.slice(0, -1).join("+") === m0);
            r.mods = same ? r.combos[0].slice(0, -1) : null;
            r.keys = same ? r.combos.map(c => c[c.length - 1]) : null;
        }
        return rows;
    }

    // A keycap
    component Cap: Rectangle {
        property string label
        implicitWidth: Math.max(22, capText.implicitWidth + 12)
        implicitHeight: 22
        radius: 5
        color: Theme.surface
        border.width: 1
        border.color: Theme.overlay
        Txt {
            id: capText
            anchors.centerIn: parent
            text: parent.label
            color: Theme.bright
            font.pixelSize: 11
        }
    }

    component Plus: Txt { text: "+"; color: Theme.muted; font.pixelSize: 11 }

    component GroupRow: GridLayout {
        id: gr
        required property var modelData
        // Many keys — the row wraps below the title
        readonly property bool wide: (modelData.mods?.length ?? 0) + (modelData.keys?.length ?? 0) > 8
        Layout.fillWidth: true
        columns: wide ? 1 : 2
        columnSpacing: 12
        rowSpacing: 4

        Txt {
            Layout.fillWidth: true
            Layout.preferredWidth: 0          // takes only the remaining space
            Layout.minimumWidth: 80
            text: gr.modelData.title
            color: Theme.text
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Shared modifiers + list of keys; a long row wraps inside the column
        Flow {
            visible: gr.modelData.mods !== null
            Layout.fillWidth: gr.wide
            Layout.preferredWidth: gr.wide ? 0 : implicitWidth
            spacing: 4
            Repeater {
                model: gr.modelData.mods ?? []
                Row {
                    required property string modelData
                    spacing: 4
                    Cap { label: parent.modelData }
                    Plus { anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Repeater {
                model: gr.modelData.keys ?? []
                Cap { required property string modelData; label: modelData }
            }
        }

        // Different modifiers — each combination separately
        Column {
            visible: gr.modelData.mods === null
            spacing: 4
            Repeater {
                model: gr.modelData.mods === null ? gr.modelData.combos : []
                Row {
                    id: combo
                    required property var modelData
                    spacing: 4
                    Repeater {
                        model: combo.modelData
                        Row {
                            required property string modelData
                            required property int index
                            spacing: 4
                            Plus { visible: index > 0; anchors.verticalCenter: parent.verticalCenter }
                            Cap { label: parent.modelData }
                        }
                    }
                }
            }
        }
    }

    Field {
        id: search
        Layout.fillWidth: true
        placeholder: I18n.t("find an action or key…", "найти действие или клавишу…")
        Component.onCompleted: input.forceActiveFocus()
    }

    // Two columns
    RowLayout {
        Layout.fillWidth: true
        spacing: 36

        Repeater {
            model: 2
            ColumnLayout {
                required property int index
                readonly property int half: Math.ceil(root.filtered.length / 2)
                readonly property real colWidth: (root.width - root.pad * 2 - 36) / 2
                Layout.preferredWidth: colWidth
                Layout.maximumWidth: colWidth
                Layout.alignment: Qt.AlignTop
                spacing: 8

                Repeater {
                    model: parent.index === 0 ? root.filtered.slice(0, parent.half) : root.filtered.slice(parent.half)
                    GroupRow {}
                }
            }
        }
    }

    Txt {
        visible: root.filtered.length === 0
        text: I18n.t("nothing found", "ничего не найдено")
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
    }
}
