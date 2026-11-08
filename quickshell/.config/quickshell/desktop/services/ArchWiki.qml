pragma Singleton
import QtQuick
import Quickshell

// A random ArchWiki article: the first paragraph, in the interface language
// (English originals or their "(Русский)" translations). Articles come from useful hubs,
// so pages about specific laptop models don't show up.
Singleton {
    id: root

    readonly property string api: "https://wiki.archlinux.org/api.php"
    readonly property string suffix: I18n.ru ? " (Русский)" : ""
    readonly property var hubs: ["General recommendations", "System maintenance", "Improving performance",
                                 "Security", "Power management"].map(h => h + suffix)

    // Is this a page in the current language? English pages have no "(Language)" suffix
    function inLanguage(t) { return I18n.ru ? t.endsWith(" (Русский)") : !/ \([^)]+\)$/.test(t); }

    // New language — new pool of articles
    Connections {
        target: I18n
        function onLangChanged() { root.pool = []; root.next(); }
    }

    property var pool: []
    property string title: ""
    property string extract: ""
    property bool ready: false

    readonly property string shortTitle: title.replace(/ \(Русский\)$/, "")
    readonly property string url: "https://wiki.archlinux.org/title/" + encodeURIComponent(title.replace(/ /g, "_"))

    function get(params, cb) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", api + "?format=json&formatversion=2&" + params);
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try { cb(JSON.parse(xhr.responseText)); return; } catch (e) {}
            }
            retry.restart();
        };
        xhr.send();
    }

    // Collect the article pool from all hubs
    function loadPool() {
        const titles = hubs.map(h => encodeURIComponent(h)).join("|");
        get("action=query&prop=links&plnamespace=0&pllimit=max&titles=" + titles, j => {
            const set = new Set();
            for (const p of j.query.pages)
                for (const l of (p.links ?? []))
                    if (root.inLanguage(l.title)) set.add(l.title);
            root.pool = Array.from(set);
            next();
        });
    }

    function decode(s) {
        return s.replace(/<[^>]*>/g, "")
                .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(n))
                .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)))
                .replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
                .replace(/\s+/g, " ").trim();
    }

    // Up to two sentences, no longer than ~240 characters
    function trimText(t) {
        const sentences = t.match(/[^.!?]+[.!?]+(\s|$)/g) ?? [t];
        let out = "";
        for (const s of sentences) {
            if (out && (out + s).length > 240) break;
            out += s;
        }
        return out.length > 260 ? out.slice(0, 257).trim() + "…" : out.trim();
    }

    function next() {
        if (pool.length === 0) { loadPool(); return; }
        const t = pool[Math.floor(Math.random() * pool.length)];
        get("action=parse&prop=text&section=0&disabletoc=1&page=" + encodeURIComponent(t), j => {
            const html = j.parse?.text ?? "";
            const re = /<p>([\s\S]*?)<\/p>/g;
            let m, text = "";
            while ((m = re.exec(html)) !== null) {
                const p = decode(m[1]);
                if (p.length > 60) { text = p; break; }
            }
            if (!text) { next(); return; }       // the article has no proper intro — take another one
            root.title = t;
            root.extract = trimText(text);
            root.ready = true;
        });
    }

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.next()
    }

    Timer { id: retry; interval: 5 * 60 * 1000; onTriggered: root.next() }
}
