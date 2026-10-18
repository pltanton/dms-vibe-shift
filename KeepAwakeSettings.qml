import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "keepAwake"

    StringSetting {
        settingKey: "presets"
        label: "Presets"
        description: "Comma-separated: durations (30m, 1h30m) or clock times (08:00 means until 8 AM)"
        placeholder: "30m, 1h, 2h, 4h, 8h, 08:00"
        defaultValue: "30m, 1h, 2h, 4h, 8h, 08:00"
    }

    StringSetting {
        settingKey: "defaultDuration"
        label: "Default duration"
        description: "Used by the Control Center tile, right-click on the bar icon, and `dms ipc call keepAwake toggle`"
        placeholder: "4h"
        defaultValue: "4h"
    }

    ToggleSetting {
        settingKey: "showTime"
        label: "Show remaining time in the bar"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideWhenOff"
        label: "Hide bar icon when off"
        description: "Show the icon only while Keep Awake is on, like the built-in idle inhibitor"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "blockLid"
        label: "Ignore lid close"
        description: "Closing the lid won't suspend while Keep Awake is on"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "keepScreenOn"
        label: "Keep screen on"
        description: "Also turn on the DMS idle inhibitor, so the screen doesn't lock or blank"
        defaultValue: false
    }
}
