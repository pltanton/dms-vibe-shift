# Keep Awake

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin that keeps the machine from suspending for a set time — including when the lid is closed.

DMS's built-in idle inhibitor only blocks the Wayland idle timer, so closing the lid still suspends. Keep Awake holds a logind inhibitor (`systemd-inhibit --what=sleep:idle:handle-lid-switch`) instead. You can still lock the screen and close the lid while a long job runs.

## Features

- Bar pill with remaining time, popout with presets (`30m, 1h, 2h, 4h, 8h` by default), custom input (`90m`, `2h30m`, `23:30`) and a live countdown
- Control Center tile: click toggles the default duration; expand for presets, custom time, lid and screen toggles
- Bar icon: owl eyes, an eye or a laptop, open while on and closed while off (or hidden while off)
- Survives a shell restart; the lock is released when the time runs out
- Optional: also turn on the DMS idle inhibitor so the screen stays on

## IPC

```sh
dms ipc call keepAwake start 4h     # 30m, 1h30m, 90 (minutes), ∞
dms ipc call keepAwake toggle       # uses the default duration
dms ipc call keepAwake status
dms ipc call keepAwake stop
```

## Requirements

- DMS >= 1.5.0
- systemd-logind (`systemd-inhibit`). Lid blocking needs `handle-lid-switch` inhibitors to be allowed by polkit, which is the default for the active session.

## Install

```sh
git clone https://github.com/pltanton/dms-keep-awake ~/.config/DankMaterialShell/plugins/keepAwake
dms ipc call plugins enable keepAwake
```

Then add the widget to the bar and/or the Control Center.
