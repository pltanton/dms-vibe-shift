# Vibe Shift

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin that keeps the laptop from suspending for a set time, even with the lid closed, so an agent can keep working overnight. The screen still blanks and locks as usual.

DMS's built-in idle inhibitor only blocks the Wayland idle timer, so closing the lid still suspends. Vibe Shift holds a logind lock instead:

```sh
systemd-run --user --unit=vibe-shift --property=RuntimeMaxSec=4h \
  systemd-inhibit --what=sleep:handle-lid-switch --mode=block sleep infinity
```

The lock lives in its own user unit, so restarting DMS doesn't drop it, and systemd ends it when the time is up.

## Features

- Control Center card: presets (`30m 1h 2h 4h 8h`), custom time (`90m`, `2h30m`, `23:30`), countdown, lid and screen toggles
- Bar icon: owl eyes, an eye or a laptop (open while on, closed while off), or an owl on a branch (empty branch while off); can be hidden while off; right-click toggles
- While on, every suspend is blocked, including Suspend from the power menu. Turn it off first.

## IPC

```sh
dms ipc call vibeShift start 4h     # 30m, 1h30m, 90 (minutes), 23:30, ∞
dms ipc call vibeShift toggle       # uses the default duration
dms ipc call vibeShift status
dms ipc call vibeShift stop
```

Without DMS: `systemctl --user status vibe-shift` / `systemctl --user stop vibe-shift`.

## Install

```sh
git clone https://github.com/pltanton/dms-vibe-shift ~/.config/DankMaterialShell/plugins/vibeShift
dms ipc call plugins enable vibeShift
```

Then add the widget to the bar and/or the Control Center. Needs DMS >= 1.5.0 and systemd.
