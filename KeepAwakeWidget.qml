import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "Duration.js" as Duration
import "."

PluginComponent {
    id: root

    readonly property real until: pluginData.until ?? 0
    readonly property real startedAt: pluginData.startedAt ?? 0
    readonly property string preset: pluginData.preset ?? ""
    readonly property var presets: Duration.parseList(pluginData.presets || "30m, 1h, 2h, 4h, 8h, 08:00")
    readonly property string defaultDuration: pluginData.defaultDuration || "4h"
    readonly property bool blockLid: pluginData.blockLid ?? true
    readonly property bool keepScreenOn: pluginData.keepScreenOn ?? false
    readonly property bool showTime: pluginData.showTime ?? true
    readonly property bool hideWhenOff: pluginData.hideWhenOff ?? false

    property real now: Date.now()
    readonly property bool active: Duration.remaining(until, now) !== 0

    function save(key, value) {
        PluginService.savePluginData("keepAwake", key, value);
    }

    function start(text) {
        const now = Date.now();
        const value = Duration.resolve(text, now);
        if (value === 0)
            return false;
        save("preset", String(text).trim());
        save("startedAt", now);
        save("until", value);
        return true;
    }

    function stop() {
        save("until", 0);
    }

    function setOption(key, value) {
        save(key, value);
    }

    onUntilChanged: now = Date.now()

    Timer {
        interval: 15000
        repeat: true
        running: root.active && root.until !== Duration.FOREVER
        onTriggered: root.now = Date.now()
    }

    visible: active || !hideWhenOff

    pillRightClickAction: () => active ? stop() : start(defaultDuration)

    ccWidgetIcon: "owl"
    ccWidgetPrimaryText: "Keep Awake"
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
        KeepAwakePanel {
            ctl: root
            onImplicitHeightChanged: root.ccDetailHeight = implicitHeight + Theme.spacingS
            Component.onCompleted: root.ccDetailHeight = implicitHeight + Theme.spacingS
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "owl"
                filled: root.active
                size: root.iconSize
                color: root.active ? Theme.primary : Theme.widgetIconColor
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

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "owl"
                filled: root.active
                size: root.iconSize
                color: root.active ? Theme.primary : Theme.widgetIconColor
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
        KeepAwakePanel {
            ctl: root
            flat: true
        }
    }

    popoutWidth: 380
}
