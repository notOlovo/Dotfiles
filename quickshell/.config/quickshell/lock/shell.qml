// ==========================================
//  QUICKSHELL — lock screen
//  Run:      ~/.config/hypr/scripts/lock.sh  (via loginctl lock-session / hypridle)
//  Preview:  QS_LOCK_PREVIEW=1 qs -c lock    (a normal window, Esc closes it, nothing is locked)
//  The password is checked by PAM with the /etc/pam.d/hyprlock profile.
// ==========================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services

ShellRoot {
    id: root

    readonly property bool preview: Quickshell.env("QS_LOCK_PREVIEW") === "1"

    // Shared state for all monitors
    property string password: ""
    property bool checking: false
    property string error: ""
    property bool unlocking: false     // the exit animation is playing

    function tryUnlock() {
        if (checking || password === "") return;
        checking = true;
        error = "";
        pam.start();
    }

    function unlocked() {
        unlocking = true;              // LockSurface fades out, then the lock is released
        unlockTimer.start();
    }

    Timer {
        id: unlockTimer
        interval: 380
        onTriggered: { lock.locked = false; Qt.quit(); }
    }

    PamContext {
        id: pam
        config: "hyprlock"
        configDirectory: "/etc/pam.d"

        onResponseRequiredChanged: {
            if (!responseRequired) return;
            respond(root.password);
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) { root.unlocked(); return; }
            root.password = "";
            root.error = result === PamResult.MaxTries ? I18n.t("too many attempts", "слишком много попыток") : I18n.t("wrong password", "неверный пароль");
        }
        onError: err => {
            root.checking = false;
            root.password = "";
            root.error = I18n.t("PAM error: ", "ошибка PAM: ") + PamError.toString(err);
        }
    }

    // For testing PAM without a real lock (preview mode only)
    IpcHandler {
        target: "lock"
        enabled: root.preview
        function tryPassword(p: string): void { root.password = p; root.tryUnlock(); }
        function state(): string { return root.checking ? "checking" : root.error || "idle"; }
    }

    // ---- The real lock ----
    WlSessionLock {
        id: lock
        locked: !root.preview

        WlSessionLockSurface {
            color: "black"
            LockSurface { anchors.fill: parent; ctx: root }
        }
    }

    // ---- Preview in a normal window ----
    LazyLoader {
        active: root.preview
        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            LockSurface {
                anchors.fill: parent
                ctx: root
                Keys.onEscapePressed: Qt.quit()
            }
        }
    }
}
