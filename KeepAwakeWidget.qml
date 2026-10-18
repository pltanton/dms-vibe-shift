import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "Duration.js" as Duration

PluginComponent {
    id: root

    readonly property real until: pluginData.until ?? 0
    readonly property var presets: Duration.parseList(pluginData.presets || "1h, 4h, 8h, ∞")
    readonly property string defaultDuration: pluginData.defaultDuration || "4h"
    property real now: Date.now()
    readonly property bool active: Duration.remaining(until, now) !== 0
    readonly property string leftText: {
        const left = Duration.remaining(until, now);
        return left === Duration.FOREVER ? "Until stopped" : Duration.label(left) + " left";
    }

    function start(text) {
        const seconds = Duration.parse(text);
        if (seconds === 0)
            return;
        PluginService.savePluginData("keepAwake", "until", seconds === Duration.FOREVER ? Duration.FOREVER : Date.now() + seconds * 1000);
    }

    function stop() {
        PluginService.savePluginData("keepAwake", "until", 0);
    }

    onUntilChanged: now = Date.now()

    Timer {
        interval: 15000
        repeat: true
        running: root.active && root.until !== Duration.FOREVER
        onTriggered: root.now = Date.now()
    }

    component PresetChips: Flow {
        spacing: Theme.spacingS

        Repeater {
            model: root.presets

            StyledRect {
                width: chipText.implicitWidth + Theme.spacingL * 2
                height: 36
                radius: Theme.cornerRadius
                color: chipArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHighest

                StyledText {
                    id: chipText
                    anchors.centerIn: parent
                    text: Duration.label(Duration.parse(modelData))
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                }

                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.start(modelData)
                }
            }
        }

        StyledRect {
            visible: root.active
            width: stopText.implicitWidth + Theme.spacingL * 2
            height: 36
            radius: Theme.cornerRadius
            color: stopArea.containsMouse ? Theme.errorHover : Theme.error

            StyledText {
                id: stopText
                anchors.centerIn: parent
                text: "Stop"
                color: Theme.errorText
                font.pixelSize: Theme.fontSizeMedium
            }

            MouseArea {
                id: stopArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stop()
            }
        }
    }

    ccWidgetIcon: "coffee"
    ccWidgetPrimaryText: "Keep Awake"
    ccWidgetSecondaryText: active ? leftText : "Off"
    ccWidgetIsActive: active
    onCcWidgetToggled: active ? stop() : start(defaultDuration)

    ccDetailContent: Component {
        StyledRect {
            implicitHeight: detailChips.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            PresetChips {
                id: detailChips
                anchors.fill: parent
                anchors.margins: Theme.spacingM
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "coffee"
                filled: root.active
                size: root.iconSize
                color: root.active ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.active
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
                name: "coffee"
                filled: root.active
                size: root.iconSize
                color: root.active ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.active
                text: Duration.short(root.until, root.now)
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Keep Awake"
            detailsText: root.active ? root.leftText : "Idle and lid close won't suspend while this is on."
            showCloseButton: true

            PresetChips {
                width: parent.width
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 180
}
