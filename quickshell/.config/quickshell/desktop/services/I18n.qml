pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Interface language from ~/.config/theme/settings.conf (language = en | ru).
// The file is watched, so `theme.py language ru` switches everything live.
//   I18n.t("Search", "Поиск")   — string for the current language
//   I18n.locale                  — Qt locale for dates and numbers
Singleton {
    id: root

    property string lang: "en"
    readonly property bool ru: lang === "ru"
    readonly property var locale: Qt.locale(ru ? "ru_RU" : "en_US")

    function t(en, ru) { return root.ru ? ru : en; }

    // Russian plural forms: plural(n, "window", "windows", "окно", "окна", "окон")
    function plural(n, en1, enN, ru1, ru2, ru5) {
        if (!root.ru) return n === 1 ? en1 : enN;
        const d = Math.abs(n) % 100, d1 = d % 10;
        if (d > 10 && d < 20) return ru5;
        if (d1 === 1) return ru1;
        if (d1 >= 2 && d1 <= 4) return ru2;
        return ru5;
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/theme/settings.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const m = text().match(/^\s*language\s*=\s*([A-Za-z]+)/m);
            const l = m ? m[1].toLowerCase() : "en";
            root.lang = l === "ru" ? "ru" : "en";
        }
    }
}
