import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "vibeShift"

    StringSetting {
        settingKey: "presets"
        label: "Presets"
        description: "Comma-separated durations, e.g. 30m, 1h30m, 4h"
        placeholder: "30m, 1h, 2h, 4h, 8h"
        defaultValue: "30m, 1h, 2h, 4h, 8h"
    }

    StringSetting {
        settingKey: "defaultDuration"
        label: "Default duration"
        description: "Used by the Control Center tile, right-click on the bar icon, and `dms ipc call vibeShift toggle`"
        placeholder: "4h"
        defaultValue: "4h"
    }

    SelectionSetting {
        settingKey: "iconStyle"
        label: "Bar icon"
        description: "Open while Vibe Shift is on, closed while it's off"
        options: [
            {
                label: "Owl eyes",
                value: "eyes"
            },
            {
                label: "Eye",
                value: "eye"
            },
            {
                label: "Laptop",
                value: "laptop"
            }
        ]
        defaultValue: "eyes"
    }

    ToggleSetting {
        settingKey: "showTime"
        label: "Show remaining time in the bar"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideWhenOff"
        label: "Hide bar icon when off"
        description: "Show the icon only while Vibe Shift is on. Otherwise the bar shows the icon with its eyes closed"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "blockLid"
        label: "Ignore lid close"
        description: "Closing the lid won't suspend while Vibe Shift is on"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "keepScreenOn"
        label: "Keep screen on"
        description: "Also turn on the DMS idle inhibitor, so the screen doesn't lock or blank"
        defaultValue: false
    }
}
