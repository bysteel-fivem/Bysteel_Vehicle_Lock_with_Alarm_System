# BySteel Vehicle Lock & Alarm System

A complete vehicle key, central locking, lockpicking, and alarm system for FiveM servers running ESX Legacy.

The resource allows authorized mechanic shops to install vehicle alarms, increases the lockpicking duration on protected vehicles, alerts emergency services through `dynamic_dispatch`, and records important actions in a STAFF Discord webhook.

## Features

- Lock and unlock owned vehicles using the `L` key or `ox_target`.
- Share and revoke temporary vehicle keys between players.
- Break into locked vehicles using a `lockpick`.
- Install vehicle alarms using the `vehicle_alarm` item.
- Restrict alarm installation by job and minimum grade.
- Configure the workshop name displayed in STAFF logs.
- Automatically increase lockpicking duration on protected vehicles.
- Activate the vehicle horn and flashing lights during an alarm.
- Send a police dispatch containing the vehicle plate, blip `161`, and color `1`.
- Remove the alarm from the database 15 seconds after a successful break-in.
- Send Discord logs for successful break-ins and alarm installations.

## Requirements

- [ESX Legacy](https://github.com/esx-framework/esx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- `fx_notify`
- `dynamic_dispatch`

The resource expects the server vehicle table to be named `owned_vehicles` and to contain a `plate` column.

## Installation

1. Extract the `bysteel_carlock` folder into your server resources directory.
2. Import `install.sql` into the database used by ESX.
3. Make sure the `lockpick` and `vehicle_alarm` items exist in `ox_inventory`.
4. Configure jobs, workshops, durations, and dispatch settings in `configs/config.lua`.
5. Configure the STAFF webhook in `server/logs.lua`.
6. Add `ensure bysteel_carlock` after its dependencies in `server.cfg`.
7. Restart the server. Restarting only this resource is sufficient after the initial SQL installation.

Recommended start order:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure ox_target
ensure ox_inventory
ensure fx_notify
ensure dynamic_dispatch
ensure bysteel_carlock
```

## Database

The included `install.sql` file creates the following column when it does not already exist:

```sql
`vehicle_alarm` TINYINT(1) NOT NULL DEFAULT 0
```

Used values:

| Value | Status |
|---:|---|
| `0` | No alarm installed |
| `1` | Alarm installed |

The SQL migration is idempotent and can be executed again without removing alarms that are already installed.

## ox_inventory Items

Add the following entries to `ox_inventory/data/items.lua` if they do not already exist. Do not duplicate an existing item entry.

```lua
['lockpick'] = {
    label = 'Lockpick',
    weight = 100,
    stack = true,
    close = true,
    description = 'A tool used to force open vehicle locks.'
},

['vehicle_alarm'] = {
    label = 'Vehicle Alarm',
    weight = 1000,
    stack = true,
    close = true,
    description = 'An alarm system ready to be installed in a vehicle.'
},
```

Restart `ox_inventory` or the server after adding the items.

## Configuring Mechanics and Workshops

Authorized jobs are configured in `BySteel.AlarmInstallation.AllowedJobs`:

```lua
AllowedJobs = {
    mechanic = 0,
    bennys = 2,
},
```

The number represents the minimum required job grade:

- `mechanic = 0` allows every grade of that job.
- `bennys = 2` allows grade 2 or higher.
- A job that is not present in the table cannot install alarms.

You can also configure the public workshop name used in STAFF logs:

```lua
WorkshopLabels = {
    mechanic = 'Los Santos Customs',
    bennys = 'Benny\'s Original Motor Works',
},
```

Authorization is checked on the client before displaying the option and verified again by the server before changing the database or removing an item.

## Alarm Installation

1. An authorized employee approaches a vehicle registered in `owned_vehicles`.
2. The employee selects **Install Alarm** through `ox_target`.
3. The server validates the job, grade, item, plate, and current alarm status.
4. When the progress action is completed, `vehicle_alarm` is changed to `1` and one item is consumed.
5. The installation is sent to the STAFF logs with the mechanic, workshop, grade, and vehicle plate.

A second alarm cannot be installed while the vehicle already has `vehicle_alarm = 1`.

## Lockpicking and Alarm Behavior

- The lockpicking option is only displayed on locked vehicles.
- Without an alarm, the action takes 7 seconds by default.
- With an alarm, the action takes 14 seconds by default.
- A dispatch alert is sent as soon as lockpicking starts on a protected vehicle.
- The vehicle lights flash and the horn sounds during the attempt.
- If the action is canceled, the alarm remains installed.
- After a successful break-in, the alarm continues for another 15 seconds.
- At the end of those 15 seconds, the database is updated to `vehicle_alarm = 0`.
- The lockpick is only consumed after a successful break-in.

Durations can be changed in `BySteel.Lockpick`:

```lua
Duration = 7000,

Alarm = {
    Duration = 14000,
    PostUnlockDuration = 15000,
    BlinkInterval = 450,
    HornDuration = 400,
}
```

All duration values are expressed in milliseconds.

## Dispatch

The dispatch integration is configured in `BySteel.Lockpick.Alarm`:

```lua
DispatchJobs = { 'police' },
DispatchMessage = 'Vehicle theft in progress',
DispatchCode = '10-60',
DispatchBlip = 161,
DispatchColor = 1,
```

The resource sends the event in the following format:

```lua
TriggerServerEvent(
    'dynamic_dispatch:CreateDispatch',
    jobs,
    message,
    code,
    coords,
    blip,
    color
)
```

Add more job names to `DispatchJobs` to notify additional departments.

## STAFF Logs

Open `server/logs.lua` and add your private Discord webhook to:

```lua
Webhook = 'YOUR_DISCORD_WEBHOOK_HERE'
```

The webhook is stored in a server-only file and is never sent to connected clients.

The following actions are logged:

- Vehicle lockpicked: player, server ID, Discord, ESX identifier, vehicle plate, and whether an alarm was installed.
- Alarm installation: mechanic, server ID, Discord, ESX identifier, workshop, job, grade, and vehicle plate.

Set `Enabled = false` in the same file if you do not want to use Discord logs.

## Quick Configuration Reference

| Setting | Location | Default |
|---|---|---:|
| Lockpick item | `BySteel.Lockpick.Item` | `lockpick` |
| Duration without alarm | `BySteel.Lockpick.Duration` | `7000` |
| Duration with alarm | `BySteel.Lockpick.Alarm.Duration` | `14000` |
| Alarm duration after entry | `BySteel.Lockpick.Alarm.PostUnlockDuration` | `15000` |
| Alarm installation item | `BySteel.AlarmInstallation.Item` | `vehicle_alarm` |
| Installation duration | `BySteel.AlarmInstallation.Duration` | `10000` |
| Authorized jobs | `BySteel.AlarmInstallation.AllowedJobs` | `mechanic` |
| Dispatch blip | `BySteel.Lockpick.Alarm.DispatchBlip` | `161` |
| Dispatch color | `BySteel.Lockpick.Alarm.DispatchColor` | `1` |

## Server Export

The resource provides a server export for sharing a vehicle key:

```lua
local success = exports['bysteel_carlock']:shareKey(playerId, plate)
```

It returns `true` when the key is assigned and `false` when the provided data is invalid or the player already has that shared key.

## Troubleshooting

### The alarm installation option is not displayed

- Make sure `BySteel.AlarmInstallation.Enabled` is set to `true`.
- Check the exact ESX job name in `AllowedJobs`.
- Make sure the player's grade meets the configured minimum.
- Make sure `BySteel.targetSupport` is set to `true`.

### The installation says the vehicle is not registered

- Make sure the plate exists in `owned_vehicles.plate`.
- Make sure your garage resource stores plates using the same format used by ESX.

### The dispatch is not displayed

- Make sure `dynamic_dispatch` starts before this resource.
- Check the job names configured in `DispatchJobs`.
- Make sure your dispatch version supports the blip and color arguments shown above.

### Discord logs are not being delivered

- Check the webhook configured in `server/logs.lua`.
- Make sure `Enabled = true`.
- Check the server console for `[bysteel_carlock] Falha ao enviar log STAFF` messages.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License or, at your option, any later version.

See `LICENSE` for the complete `GPL-3.0-or-later` license terms.

Copyright © 2026 BySteel.
