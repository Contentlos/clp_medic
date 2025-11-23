# CLP Medic System

Standalone ESX medic system built for ox_target and ox_inventory. Designed to gradually replace `esx_ambulancejob` while letting you toggle compatibility during migration.

## Features
- On/Off-duty system at configurable duty points (ox_target zones)
- Revive, stabilize (light/medium/heavy), painkillers, and EKG status checks with animations and progress bars
- Added: cyberpunk-style death/injury NUI overlay with animated EKG line, manual distress hint, and state text (stable/unstable/flatline)
- Added: dispatch/Leitstelle tablet UI (F6 or command) with EMS calls, assignments, completion tracking, and alert pulse/sound for new calls
- Medic bag item that opens a treatment menu for the closest patient
- Added: defibrillator item for advanced revive attempts with configurable success chance
- Added: carry interaction to move downed players and put them down again
- Added: dedicated healing action for injured but conscious players (separate from revive)
- Garage with configurable vehicles, spawns with livery index 4 and all extras enabled by default
- Simple patient vitals feedback (stable/unstable/critical based on health)
- No hard dependency on `esx_ambulancejob`; compatibility toggle provided

## Files
- `fxmanifest.lua` – resource manifest
- `config.lua` – all positions, items, vehicles, timing values, and compatibility flags
- `client/main.lua` – duty handling, player interactions, medic bag flow, vitals (resets NUI on revive)
- `client/garage.lua` – garage target zones and spawn logic (livery 4, extras on)
- `client/deathscreen.lua` – death screen + EKG overlay control (manual dispatch key prompt)
- `client/carry.lua` – ox_target player options for carrying/putting down patients
- `client/defib.lua` – defibrillator item usability and animation
- `server/main.lua` – duty state tracking, usable medic bag registration
- `server/medical.lua` – server-side treatment validation and effects (including defib)
- `server/carry.lua` – carry synchronization
- `html/` – NUI assets for the death/injury overlay

## Configuration
Update `config.lua` to match your server:
- `Config.Compatibility.UseAmbulanceJob` – keep job lock to EMS job names in `Config.AllowedJobs`; set false to allow other jobs.
- `Config.AllowedJobs` – set to your EMS job name (e.g. `ems`).
- `Config.DutyStations` – add/remove duty locations.
- `Config.Garages` – add more garage zones and vehicles. Each vehicle entry has `model` and `label`.
- `Config.Items` – change item names to match your ox_inventory items.
- `Config.TreatmentTimes` / `Config.HealthAdjust` – tune how long treatments take and how much health is restored.
- `Config.Defib` – success chance + notifications for the defibrillator flow.
- `Config.Dispatch` – command name, panic key (default G) to send a dispatch while downed, F6 keybind for the tablet, alert sounds, on-duty requirements.

### Adding vehicles
Append to `Config.Garages[<index>].vehicles`:
```lua
{ model = 'emsbike', label = 'Medic Bike' }
```
Vehicles always spawn with livery index 4 (`Config.VehicleLivery`) and all extras enabled when `Config.EnableAllExtras = true`.

### Adding medical items
Add or rename items in `Config.Items`. Make sure they exist in ox_inventory. Example SQL for `ox_inventory` items table:
```sql
INSERT INTO items (name, label, weight, stack, closeonuse, description) VALUES
  ('medic_bag', 'Medic Bag', 500, 1, 1, 'Öffnet ein Behandlungsmenü'),
  ('med_bandage', 'Bandage', 50, 5, 1, 'Verband für Wunden'),
  ('painkillers', 'Painkillers', 20, 5, 1, 'Schmerzmittel'),
  ('med_ekg', 'Portable EKG', 200, 1, 1, 'Vitalzeichen prüfen'),
  ('med_adrenaline', 'Adrenaline Shot', 100, 5, 1, 'Erweiterte Wiederbelebung'),
  ('defib', 'Defibrillator', 500, 1, 1, 'Elektrischer Defibrillator für Revives');
```

## Usage notes
- Only on-duty medics can use medic interactions and the garage. Duty toggles are defined in `Config.DutyStations`.
- Medic bag (`Config.Items.medicBag`) is registered as usable; when used, it opens a context menu for the nearest player within `Config.PatientRange`.
- Treatments consume the relevant item (bandages, painkillers, adrenaline/defib) and apply effects on the target.
- Defibrillator (`Config.Items.defib`) uses a short charge animation; success is controlled by `Config.Defib.SuccessChance`.
- Carry interaction is available on downed players via ox_target; medics can also place the patient down through the stop option.
- EKG checks return simple vitals (health number + stable/instable/critical label) and update the NUI overlay.
- Garages use ox_target sphere zones; coordinates (`coords`/`spawn`) and headings can be changed per garage in `config.lua`.

## Migration tips
- Keep `Config.Compatibility.UseAmbulanceJob = true` while `esx_ambulancejob` is active so only the EMS job(s) in `Config.AllowedJobs` can go on duty.
- Set it to `false` when fully migrated to allow custom jobs or whitelist logic.
- `Config.Compatibility.AllowLegacyAlerts` is provided for custom bridging if you need to forward calls to legacy scripts (left false by default).

## Dispatch / Leitstelle
- EMS-only tablet (`/ems` by default) shows active calls, assignment status, and completion buttons.
- Calls can be created via the panic key while downed (default **G**), the `/ems` command, or automatically if `Config.Dispatch.AutoOnDeath = true`; completing a revive clears the call.
- Changing the command or requiring on-duty access is handled in `Config.Dispatch`.

## Testing
This resource has not been run inside this environment. Configure item names, job names, and coordinates for your server before deployment.
