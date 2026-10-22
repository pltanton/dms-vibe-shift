import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "Duration.js" as Duration
import "."

PluginComponent {
    id: root

    property var shift: PluginService.getGlobalVar("vibeShift", "state", null) ?? {}
    readonly property real until: shift.until ?? 0
    readonly property string preset: shift.preset ?? ""
    readonly property var presets: Duration.parseList(pluginData.presets || "30m, 1h, 2h, 4h, 8h")
    readonly property string defaultDuration: pluginData.defaultDuration || "4h"
    readonly property bool blockLid: pluginData.blockLid ?? true
    readonly property bool keepScreenOn: pluginData.keepScreenOn ?? false
    readonly property bool showTime: pluginData.showTime ?? true
    readonly property bool hideWhenOff: pluginData.hideWhenOff ?? false
    readonly property string iconStyle: pluginData.iconStyle || "eyes"

    property real now: Date.now()
    readonly property bool active: Duration.remaining(until, now) !== 0

    function request(action, text) {
        PluginService.setGlobalVar("vibeShift", "request", {
            "action": action,
            "text": text,
            "seq": Date.now() + Math.random()
        });
    }

    function start(text) {
        if (Duration.resolve(text, Date.now()) === 0)
            return false;
        request("start", text);
        return true;
    }

    function stop() {
        request("stop", "");
    }

    function setOption(key, value) {
        PluginService.savePluginData("vibeShift", key, value);
    }

    Connections {
        target: PluginService

        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === "vibeShift" && varName === "state")
                root.shift = PluginService.getGlobalVar("vibeShift", "state", null) ?? {};
        }
    }

    onUntilChanged: now = Date.now()

    Timer {
        interval: 15000
        repeat: true
        running: root.active && root.until !== Duration.FOREVER
        onTriggered: root.now = Date.now()
    }

    readonly property bool shown: active || !hideWhenOff

    pillRightClickAction: () => active ? stop() : start(defaultDuration)

    ccWidgetIcon: ({
            "eyes": "owl",
            "eye": active ? "visibility" : "visibility_off",
            "laptop": "laptop",
            "branch": "owl"
        })[iconStyle] ?? "owl"
    ccWidgetPrimaryText: "Vibe Shift"
    ccWidgetSecondaryText: {
        if (!active)
            return "Off";
        if (until === Duration.FOREVER)
            return "Until turned off";
        return Duration.short(until, now) + " left";
    }
    ccWidgetIsActive: active
    onCcWidgetToggled: active ? stop() : start(defaultDuration)

    ccDetailContent: Component {
        VibeShiftPanel {
            ctl: root
            onImplicitHeightChanged: root.ccDetailHeight = implicitHeight + Theme.spacingS
            Component.onCompleted: root.ccDetailHeight = implicitHeight + Theme.spacingS
        }
    }

    horizontalBarPill: shown ? horizontalPill : null
    verticalBarPill: shown ? verticalPill : null

    component PillIcon: AwakeIcon {
        style: root.iconStyle
        awake: root.active
        size: root.iconSize
        color: root.active ? Theme.primary : Theme.widgetIconColor
    }

    Component {
        id: horizontalPill

        Row {
            spacing: Theme.spacingXS

            PillIcon {
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.active && root.showTime
                text: Duration.short(root.until, root.now)
                color: Theme.primary
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: verticalPill

        Column {
            spacing: Theme.spacingXS

            PillIcon {
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.active && root.showTime
                text: Duration.short(root.until, root.now)
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        VibeShiftPanel {
            ctl: root
            flat: true
        }
    }

    popoutWidth: 380
}
