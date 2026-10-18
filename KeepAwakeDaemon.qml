import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "Duration.js" as Duration

PluginComponent {
    id: root

    readonly property real until: pluginData.until ?? 0
    readonly property string defaultDuration: pluginData.defaultDuration || "4h"
    readonly property bool blockLid: pluginData.blockLid ?? true
    readonly property bool keepScreenOn: pluginData.keepScreenOn ?? false

    property var proc: null
    property string heldKey: ""
    property bool ownsScreenInhibit: false

    function setUntil(value) {
        PluginService.savePluginData("keepAwake", "until", value);
    }

    function start(text) {
        const seconds = Duration.parse(text);
        if (seconds === 0)
            return false;
        setUntil(seconds === Duration.FOREVER ? Duration.FOREVER : Date.now() + seconds * 1000);
        return true;
    }

    function stop() {
        setUntil(0);
    }

    function apply() {
        expiry.stop();
        const left = Duration.remaining(until, Date.now());
        if (left === 0) {
            release();
            if (until !== 0)
                stop();
            return;
        }
        const key = until + "/" + blockLid;
        if (!proc || heldKey !== key) {
            hold(left);
            heldKey = key;
        }
        if (left !== Duration.FOREVER) {
            expiry.interval = Math.min(left * 1000, 0x7fffffff);
            expiry.start();
        }
    }

    // `sleep` gets the remaining time too, so an orphaned inhibitor still lets go on its own.
    function hold(seconds) {
        release();
        const what = blockLid ? "sleep:idle:handle-lid-switch" : "sleep:idle";
        proc = inhibitComponent.createObject(root, {
            command: ["systemd-inhibit", "--what=" + what, "--who=Keep Awake", "--why=Keep Awake plugin for DankMaterialShell", "--mode=block", "sleep", seconds === Duration.FOREVER ? "infinity" : String(seconds)]
        });
        proc.running = true;
        syncScreen();
    }

    function release() {
        if (proc) {
            proc.released = true;
            proc.running = false;
            proc = null;
        }
        syncScreen();
    }

    function syncScreen() {
        const want = proc !== null && keepScreenOn;
        if (want && !ownsScreenInhibit && !SessionService.idleInhibited) {
            SessionService.enableIdleInhibit();
            ownsScreenInhibit = true;
        } else if (!want && ownsScreenInhibit) {
            ownsScreenInhibit = false;
            SessionService.disableIdleInhibit();
        }
    }

    function status() {
        const left = Duration.remaining(until, Date.now());
        if (left === 0)
            return "off";
        return left === Duration.FOREVER ? "on, until stopped" : "on, " + Duration.label(left) + " left";
    }

    onUntilChanged: apply()
    onBlockLidChanged: apply()
    onKeepScreenOnChanged: syncScreen()
    Component.onCompleted: Qt.callLater(apply)
    Component.onDestruction: release()

    Timer {
        id: expiry
        onTriggered: {
            if (Duration.remaining(root.until, Date.now()) === 0)
                ToastService.showInfo("Keep Awake ended", "Sleep on idle and lid close is back.");
            root.apply();
        }
    }

    Component {
        id: inhibitComponent

        Process {
            property bool released: false

            onStarted: {
                if (released)
                    running = false;
            }

            stderr: StdioCollector {
                onStreamFinished: {
                    if (text.trim())
                        console.warn("keepAwake: systemd-inhibit:", text.trim());
                }
            }

            onExited: exitCode => {
                if (!released && root.proc === this) {
                    root.proc = null;
                    if (exitCode === 0)
                        ToastService.showInfo("Keep Awake ended", "Sleep on idle and lid close is back.");
                    else
                        ToastService.showError("Keep Awake failed", "systemd-inhibit exited with code " + exitCode);
                    root.stop();
                }
                destroy();
            }
        }
    }

    IpcHandler {
        target: "keepAwake"

        function start(duration: string): string {
            return root.start(duration) ? root.status() : "bad duration: " + duration;
        }

        function stop(): string {
            root.stop();
            return "off";
        }

        function toggle(): string {
            if (root.proc)
                root.stop();
            else
                root.start(root.defaultDuration);
            return root.status();
        }

        function status(): string {
            return root.status();
        }
    }
}
