pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System resources: read straight from /proc and /sys, no external tools.
Singleton {
    id: root

    property int interval: 2000

    property real cpu: 0                 // 0..1
    property var  cpuHistory: []         // the last 40 samples (~80 s)
    property real ram: 0
    property real ramUsed: 0             // GiB
    property real ramTotal: 0
    property real gpu: 0
    property real cpuTemp: 0             // °C
    property real gpuTemp: 0
    property real ssdTemp: 0
    property real netDown: 0             // bytes/s
    property real netUp: 0
    property real disk: 0
    property real diskUsed: 0            // GiB
    property real diskTotal: 0
    property int  battery: -1
    property string batteryStatus: ""
    property real batteryWatts: 0

    // Sensor paths are found once at startup (hwmon numbers move around)
    property var paths: ({})

    property var _cpuPrev: null
    property var _netPrev: null

    function fmtSpeed(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + I18n.t(" MB/s", " МБ/с");
        if (b >= 1024)    return Math.round(b / 1024) + I18n.t(" KB/s", " КБ/с");
        return Math.round(b) + I18n.t(" B/s", " Б/с");
    }

    Process {
        running: true
        command: ["sh", "-c",
            "for h in /sys/class/hwmon/hwmon*; do echo \"hwmon:$(cat $h/name) $h\"; done;" +
            "for g in /sys/class/drm/card*/device/gpu_busy_percent; do [ -e \"$g\" ] && echo \"gpu $g\" && break; done;" +
            "for b in /sys/class/power_supply/BAT*; do [ -e \"$b\" ] && echo \"bat $b\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf(" ");
                    p[line.slice(0, i)] = line.slice(i + 1);
                }
                root.paths = p;
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload(); net.reload();
            if (root.paths.gpu) gpuBusy.reload();
            if (root.paths["hwmon:k10temp"]) cpuT.reload();
            if (root.paths["hwmon:amdgpu"])  gpuT.reload();
            if (root.paths["hwmon:nvme"])    ssdT.reload();
            if (root.paths.bat) { batCap.reload(); batStat.reload(); batPow.reload(); }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root._cpuPrev) {
                const dt = total - root._cpuPrev.total;
                root.cpu = dt > 0 ? 1 - (idle - root._cpuPrev.idle) / dt : 0;
                root.cpuHistory = root.cpuHistory.concat([root.cpu]).slice(-40);
            }
            root._cpuPrev = { total, idle };
        }
    }

    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const kb = k => Number((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = kb("MemTotal"), avail = kb("MemAvailable");
            root.ramTotal = total / 1048576;
            root.ramUsed = (total - avail) / 1048576;
            root.ram = total > 0 ? (total - avail) / total : 0;
        }
    }

    FileView {
        id: net
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const [iface, rest] = line.split(":");
                if (!rest || iface.trim() === "lo") continue;
                const f = rest.trim().split(/\s+/).map(Number);
                rx += f[0]; tx += f[8];
            }
            const now = Date.now();
            if (root._netPrev) {
                const dt = (now - root._netPrev.t) / 1000;
                root.netDown = Math.max(0, (rx - root._netPrev.rx) / dt);
                root.netUp = Math.max(0, (tx - root._netPrev.tx) / dt);
            }
            root._netPrev = { t: now, rx, tx };
        }
    }

    FileView { id: gpuBusy; path: root.paths.gpu ?? ""; printErrors: false
        onLoaded: root.gpu = Number(text()) / 100 }
    FileView { id: cpuT; path: root.paths["hwmon:k10temp"] ? root.paths["hwmon:k10temp"] + "/temp1_input" : ""; printErrors: false
        onLoaded: root.cpuTemp = Number(text()) / 1000 }
    FileView { id: gpuT; path: root.paths["hwmon:amdgpu"] ? root.paths["hwmon:amdgpu"] + "/temp1_input" : ""; printErrors: false
        onLoaded: root.gpuTemp = Number(text()) / 1000 }
    FileView { id: ssdT; path: root.paths["hwmon:nvme"] ? root.paths["hwmon:nvme"] + "/temp1_input" : ""; printErrors: false
        onLoaded: root.ssdTemp = Number(text()) / 1000 }

    FileView { id: batCap;  path: root.paths.bat ? root.paths.bat + "/capacity" : ""; printErrors: false
        onLoaded: root.battery = Number(text()) }
    FileView { id: batStat; path: root.paths.bat ? root.paths.bat + "/status" : ""; printErrors: false
        onLoaded: root.batteryStatus = text().trim() }
    FileView { id: batPow;  path: root.paths.bat ? root.paths.bat + "/power_now" : ""; printErrors: false
        onLoaded: root.batteryWatts = Number(text()) / 1e6 }

    Process {
        id: df
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [used, size] = text.trim().split("\n")[1].trim().split(/\s+/).map(Number);
                root.diskUsed = used / 1073741824;
                root.diskTotal = size / 1073741824;
                root.disk = size > 0 ? used / size : 0;
            }
        }
    }
}
