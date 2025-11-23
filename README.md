# CLP Medic System

Standalone ESX medic system built for ox_target and ox_inventory. Designed to gradually replace `esx_ambulancejob` while letting you toggle compatibility during migration.

## Features
- On/Off-duty system at configurable duty points (ox_target zones)
- Revive, stabilize (light/medium/heavy), painkillers, and EKG status checks with animations and progress bars
- Medic bag item that opens a treatment menu for the closest patient
- Garage with configurable vehicles, spawns with livery index 4 and all extras enabled by default
- Simple patient vitals feedback (stable/unstable/critical based on health)
- No hard dependency on `esx_ambulancejob`; compatibility toggle provided

## Files
- `fxmanifest.lua` – resource manifest
- `config.lua` – all positions, items, vehicles, timing values, and compatibility flags
- `client/main.lua` – duty handling, player interactions, medic bag flow, vitals
- `client/garage.lua` – garage target zones and spawn logic (livery 4, extras on)
- `server/main.lua` – duty state tracking, usable medic bag registration
- `server/medical.lua` – server-side treatment validation and effects

## Configuration
Update `config.lua` to match your server:
- `Config.Compatibility.UseAmbulanceJob` – keep job lock to `ambulance` while migrating; set false to allow other jobs.
- `Config.DutyStations` – add/remove duty locations.
- `Config.Garages` – add more garage zones and vehicles. Each vehicle entry has `model` and `label`.
- `Config.Items` – change item names to match your ox_inventory items.
- `Config.TreatmentTimes` / `Config.HealthAdjust` – tune how long treatments take and how much health is restored.

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
  ('med_adrenaline', 'Adrenaline Shot', 100, 5, 1, 'Erweiterte Wiederbelebung');
```

## Usage notes
- Only on-duty medics can use medic interactions and the garage. Duty toggles are defined in `Config.DutyStations`.
- Medic bag (`Config.Items.medicBag`) is registered as usable; when used, it opens a context menu for the nearest player within `Config.PatientRange`.
- Treatments consume the relevant item (bandages, painkillers, adrenaline) and apply effects on the target.
- EKG checks return simple vitals (health number + stable/instable/critical label).
- Garages use ox_target sphere zones; coordinates (`coords`/`spawn`) and headings can be changed per garage in `config.lua`.

## Migration tips
- Keep `Config.Compatibility.UseAmbulanceJob = true` while `esx_ambulancejob` is active so only the ambulance job can go on duty.
- Set it to `false` when fully migrated to allow custom jobs or whitelist logic.
- `Config.Compatibility.AllowLegacyAlerts` is provided for custom bridging if you need to forward calls to legacy scripts (left false by default).

## Testing
This resource has not been run inside this environment. Configure item names, job names, and coordinates for your server before deployment.
