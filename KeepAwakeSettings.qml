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
        description: "Comma-separated durations shown in the popout, e.g. 30m, 1h30m, 4h, ∞"
        placeholder: "1h, 4h, 8h, ∞"
        defaultValue: "1h, 4h, 8h, ∞"
    }

    StringSetting {
        settingKey: "defaultDuration"
        label: "Default duration"
        description: "Used by the Control Center toggle and `dms ipc call keepAwake toggle`"
        placeholder: "4h"
        defaultValue: "4h"
    }

    ToggleSetting {
        settingKey: "blockLid"
        label: "Ignore lid close"
        description: "Closing the lid doesn't suspend while Keep Awake is on"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "keepScreenOn"
        label: "Keep screen on"
        description: "Also turn on the DMS idle inhibitor, so the screen doesn't lock or blank"
        defaultValue: false
    }
}
