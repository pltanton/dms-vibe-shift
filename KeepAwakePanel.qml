import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import "Duration.js" as Duration

Rectangle {
    id: panel

    required property var ctl
    property bool flat: false

    readonly property real contentWidth: width - Theme.spacingL * 2
    readonly property bool timed: ctl.active && ctl.until !== Duration.FOREVER
    readonly property real total: ctl.startedAt > 0 && timed ? ctl.until - ctl.startedAt : 0

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
        color: selected ? Theme.primary : chipArea.containsMouse ? (danger ? Theme.errorPressed : Theme.primaryPressed) : Theme.floatingSurface
        border.color: selected ? Theme.primary : Theme.outlineStrong
        border.width: 1

        readonly property color fg: selected ? Theme.primaryText : (danger && chipArea.containsMouse ? Theme.error : Theme.surfaceText)

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            DankIcon {
                visible: chip.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: chip.icon
                size: Theme.iconSizeSmall
                color: chip.fg
            }

            StyledText {
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
        width: panel.contentWidth
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        Item {
            width: parent.width
            height: Math.max(headerIcon.height, headerText.implicitHeight, countdown.implicitHeight)

            DankIcon {
                id: headerIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                name: "visibility"
                filled: panel.ctl.active
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
                    text: "Keep Awake"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: {
                        if (!panel.ctl.active)
                            return "Off · sleeps on idle and lid close";
                        if (!panel.timed)
                            return "On until you turn it off";
                        return "Until " + Duration.clock(panel.ctl.until, SettingsData.use24HourClock);
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                }
            }

            StyledText {
                id: countdown
                visible: panel.ctl.active
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!panel.timed)
                        return "∞";
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

        Rectangle {
            visible: panel.total > 0
            width: parent.width
            height: 4
            radius: 2
            color: Theme.floatingSurface

            Rectangle {
                height: parent.height
                radius: parent.radius
                color: Theme.primary
                width: parent.width * Math.max(0, Math.min(1, (panel.ctl.until - panel.ctl.now) / panel.total))
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
                    onClicked: panel.ctl.start(modelData)
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            DankTextField {
                id: customField
                width: parent.width - startChip.width - Theme.spacingS
                placeholderText: "Custom: 90m, 2h30m, 23:30"
                onAccepted: startChip.clicked()
            }

            Chip {
                id: startChip
                anchors.verticalCenter: customField.verticalCenter
                width: Math.max(96, implicitWidth)
                icon: "play_arrow"
                label: "Start"
                onClicked: {
                    if (panel.ctl.start(customField.text))
                        customField.text = "";
                    else
                        ToastService.showWarning("Keep Awake", "Can't read \"" + customField.text + "\". Try 90m, 2h30m or 23:30.");
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
                icon: "bedtime"
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

        DankToggle {
            width: parent.width
            text: "Ignore lid close"
            description: "Closing the lid won't suspend"
            checked: panel.ctl.blockLid
            onToggled: checked => panel.ctl.setOption("blockLid", checked)
        }

        DankToggle {
            width: parent.width
            text: "Keep screen on"
            description: "Don't lock or blank the screen on idle"
            checked: panel.ctl.keepScreenOn
            onToggled: checked => panel.ctl.setOption("keepScreenOn", checked)
        }
    }
}
