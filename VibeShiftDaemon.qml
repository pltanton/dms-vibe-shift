import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "Duration.js" as Duration

// The lock lives in a transient user unit, so DMS restarts don't touch it; this only drives and watches the unit.
PluginComponent {
    id: root

    readonly property string unit: "vibe-shift.service"
    readonly property string defaultDuration: pluginData.defaultDuration || "4h"
    readonly property bool blockLid: pluginData.blockLid ?? true
    readonly property bool keepScreenOn: pluginData.keepScreenOn ?? false
    readonly property bool lockOnLid: pluginData.lockOnLid ?? true

    // Suspend normally does the locking, and it's blocked now, so lock when the lid shuts on the laptop panel alone.
    readonly property string lidWatch: 'external() { for f in /sys/class/drm/card*-*/status; do case "$f" in *eDP*|*LVDS*|*DSI*) ;; *) [ "$(cat "$f")" = connected ] && return 0 ;; esac; done; return 1; }; ' + 'was=0; while sleep 2; do if [ "$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed)" = "b true" ]; then ' + '[ $was = 0 ] && ! external && dms ipc call lock lock; was=1; else was=0; fi; done'

    property real until: 0
    property string preset: ""
    property bool busy: false
    property bool loaded: false
    property real launchedAt: 0
    property bool ownsScreenInhibit: false
    readonly property bool active: until !== 0

    function publish() {
        PluginService.setGlobalVar("vibeShift", "state", {
            "until": until,
            "preset": preset
        });
        syncScreen();
        if (active && until !== Duration.FOREVER)
            expiry.restart();
        else
            expiry.stop();
    }

    function run(command, done) {
        busy = true;
        Proc.runCommand("vibeShift.cmd", command, (out, code) => {
            busy = false;
            done(code);
        }, 0);
    }

    function start(text) {
        const value = Duration.resolve(text, Date.now());
        if (value === 0)
            return false;
        launch(value, String(text).trim());
        return true;
    }

    function launch(value, presetText) {
        const cmd = ["systemd-run", "--user", "--unit=" + unit, "--collect", "--quiet", "--setenv=PATH", "--description=Vibe Shift until=" + value + " preset=" + presetText];
        if (value !== Duration.FOREVER)
            cmd.push("--property=RuntimeMaxSec=" + Duration.remaining(value, Date.now()));
        cmd.push("systemd-inhibit", "--what=" + (blockLid ? "sleep:handle-lid-switch" : "sleep"), "--who=Vibe Shift", "--why=Vibe Shift plugin for DankMaterialShell", "--mode=block");
        cmd.push.apply(cmd, blockLid && lockOnLid ? ["sh", "-c", lidWatch] : ["sleep", "infinity"]);
        until = value;
        preset = presetText;
        launchedAt = Date.now();
        publish();
        run(["sh", "-c", 'systemctl --user stop "$0" 2>/dev/null; systemctl --user reset-failed "$0" 2>/dev/null; exec "$@"', unit].concat(cmd), code => {
            if (code !== 0)
                fail("systemd-run exited with code " + code);
            else
                verify.restart();
        });
    }

    function stop() {
        until = 0;
        preset = "";
        publish();
        run(["systemctl", "--user", "stop", unit], () => {});
    }

    function fail(reason) {
        ToastService.showError("Vibe Shift failed", reason + ". See: journalctl --user -u " + unit);
        until = 0;
        preset = "";
        publish();
    }

    function refresh() {
        if (busy)
            return;
        Proc.runCommand("vibeShift.status", ["systemctl", "--user", "show", unit, "-p", "ActiveState", "-p", "Description"], (out, code) => {
            if (busy)
                return;
            const running = /^ActiveState=(active|activating)$/m.test(out);
            const m = /^Description=Vibe Shift until=(-?\d+) preset=(.*)$/m.exec(out);
            if (running && m) {
                until = Number(m[1]);
                preset = m[2];
            } else if (until !== 0) {
                if (Date.now() - launchedAt < 5000)
                    return fail("The sleep lock was refused");
                if (loaded && Duration.remaining(until, Date.now()) === 0)
                    ToastService.showInfo("Vibe Shift ended", "Sleep on idle and lid close is back.");
                until = 0;
                preset = "";
            }
            loaded = true;
            publish();
        }, 0);
    }

    function syncScreen() {
        const want = active && keepScreenOn;
        if (want && !ownsScreenInhibit) {
            ownsScreenInhibit = true;
            SessionService.enableIdleInhibit();
        } else if (!want && ownsScreenInhibit) {
            ownsScreenInhibit = false;
            SessionService.disableIdleInhibit();
        }
    }

    function status() {
        const left = Duration.remaining(until, Date.now());
        if (left === 0)
            return "off";
        return left === Duration.FOREVER ? "on, until stopped" : "on, " + Duration.label(left) + " left, until " + Duration.clock(until, true);
    }

    onBlockLidChanged: relaunch()
    onLockOnLidChanged: relaunch()

    function relaunch() {
        if (loaded && active)
            launch(until, preset);
    }
    onKeepScreenOnChanged: syncScreen()
    Component.onCompleted: refresh()

    Connections {
        target: PluginService

        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId !== "vibeShift" || varName !== "request")
                return;
            const r = PluginService.getGlobalVar("vibeShift", "request", null);
            if (r?.action === "start")
                root.start(r.text);
            else if (r?.action === "stop")
                root.stop();
        }
    }

    Timer {
        interval: root.active ? 15000 : 60000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: verify
        interval: 1500
        onTriggered: root.refresh()
    }

    Timer {
        id: expiry
        interval: Math.min(Math.max(1000, root.until - Date.now() + 1000), 0x7fffffff)
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "vibeShift"

        function start(duration: string): string {
            return root.start(duration) ? root.status() : "bad duration: " + duration;
        }

        function stop(): string {
            root.stop();
            return "off";
        }

        function toggle(): string {
            if (root.active)
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
