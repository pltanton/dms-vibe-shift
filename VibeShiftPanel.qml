import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "Duration.js" as Duration
import "."

Rectangle {
    id: panel

    required property var ctl
    property bool flat: false

    readonly property bool timed: ctl.active && ctl.until !== Duration.FOREVER
    readonly property bool customActive: ctl.active && ctl.preset !== "∞" && ctl.presets.indexOf(ctl.preset) < 0
    property bool showCustom: false

    implicitHeight: content.implicitHeight + Theme.spacingL * 2
    radius: Theme.cornerRadius
    color: flat ? "transparent" : Theme.nestedSurface
    border.color: Theme.outlineMedium
    border.width: flat ? 0 : Theme.layerOutlineWidth

    Timer {
        interval: 1000
        repeat: true
        running: panel.visible && panel.timed
        onTriggered: panel.ctl.now = Date.now()
    }

    component Chip: Rectangle {
        id: chip

        property string label: ""
        property string icon: ""
        property bool selected: false
        property bool danger: false
        signal clicked

        height: 36
        radius: Theme.cornerRadius
        color: selected ? Theme.ccTileActiveBg : chipArea.containsMouse ? Qt.tint(Theme.ccPillInactiveBg, danger ? Theme.errorPressed : Theme.primaryPressed) : Theme.ccPillInactiveBg

        readonly property color fg: selected ? Theme.ccTileActiveText : (danger && chipArea.containsMouse ? Theme.error : Theme.surfaceText)

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            DIcon {
                visible: chip.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: chip.icon
                size: Theme.iconSizeSmall
                color: chip.fg
            }

            StyledText {
                visible: chip.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: chip.fg
            }
        }

        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        Item {
            width: parent.width
            height: Math.max(headerIcon.height, headerText.implicitHeight, countdown.implicitHeight)

            AwakeIcon {
                id: headerIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                style: panel.ctl.iconStyle
                awake: panel.ctl.active
                size: Theme.iconSizeLarge
                color: panel.ctl.active ? Theme.primary : Theme.surfaceText
            }

            Column {
                id: headerText
                anchors.left: headerIcon.right
                anchors.leftMargin: Theme.spacingM
                anchors.right: countdown.visible ? countdown.left : parent.right
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXXS

                StyledText {
                    width: parent.width
                    text: "Vibe Shift"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: {
                        if (!panel.ctl.active)
                            return "Sleeps on idle and lid close as usual";
                        if (!panel.timed)
                            return "Awake until you turn it off";
                        return Duration.label(Duration.remaining(panel.ctl.until, panel.ctl.now)) + " left · until " + Duration.clock(panel.ctl.until, SettingsData.use24HourClock);
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                }
            }

            StyledText {
                id: countdown
                visible: panel.timed
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const r = Duration.remaining(panel.ctl.until, panel.ctl.now);
                    const h = Math.floor(r / 3600), m = Math.floor(r % 3600 / 60), s = r % 60;
                    return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m)) + ":" + String(s).padStart(2, "0");
                }
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.Medium
                isMonospace: true
                color: Theme.primary
            }
        }

        Grid {
            id: presetGrid
            width: parent.width
            columns: 3
            columnSpacing: Theme.spacingS
            rowSpacing: Theme.spacingS

            Repeater {
                model: panel.ctl.presets

                Chip {
                    required property string modelData
                    width: (presetGrid.width - Theme.spacingS * 2) / 3
                    label: Duration.presetLabel(modelData)
                    selected: panel.ctl.active && panel.ctl.preset === modelData
                    onClicked: {
                        panel.showCustom = false;
                        panel.ctl.start(modelData);
                    }
                }
            }

            Chip {
                width: (presetGrid.width - Theme.spacingS * 2) / 3
                icon: "edit"
                label: "Custom"
                selected: panel.showCustom || panel.customActive
                onClicked: panel.showCustom = !panel.showCustom
            }
        }

        Row {
            visible: panel.showCustom
            width: parent.width
            spacing: Theme.spacingS

            DTextField {
                id: customField
                width: parent.width - startChip.width - Theme.spacingS
                placeholderText: "Custom: 90m, 2h30m or 23:30"
                hidePlaceholderOnFocus: false
                onAccepted: startChip.clicked()
            }

            Chip {
                id: startChip
                anchors.verticalCenter: customField.verticalCenter
                width: 56
                icon: "play_arrow"
                onClicked: {
                    if (panel.ctl.start(customField.text)) {
                        customField.text = "";
                        panel.showCustom = false;
                    }
                    else
                        ToastService.showWarning("Vibe Shift", "Can't read \"" + customField.text + "\". Try 90m, 2h30m or 23:30.");
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            Chip {
                width: panel.ctl.active ? (parent.width - Theme.spacingS) / 2 : parent.width
                icon: "all_inclusive"
                label: "Until I turn it off"
                selected: panel.ctl.active && !panel.timed
                onClicked: panel.ctl.start("∞")
            }

            Chip {
                visible: panel.ctl.active
                width: (parent.width - Theme.spacingS) / 2
                icon: "stop"
                label: "Turn off"
                danger: true
                onClicked: panel.ctl.stop()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineMedium
        }

        DToggle {
            width: parent.width
            text: "Ignore lid close"
            description: "Closing the lid won't suspend"
            checked: panel.ctl.blockLid
            onToggled: checked => panel.ctl.setOption("blockLid", checked)
        }

        DToggle {
            width: parent.width
            text: "Keep screen on"
            description: "Don't lock or blank the screen on idle"
            checked: panel.ctl.keepScreenOn
            onToggled: checked => panel.ctl.setOption("keepScreenOn", checked)
        }
    }
}
