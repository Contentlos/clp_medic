Config = {}

-- Toggle legacy compatibility. This does not hard-require esx_ambulancejob,
-- but lets you keep its job name/grades active during the transition.
Config.Compatibility = {
    UseAmbulanceJob = true, -- require EMS job names from Config.AllowedJobs (use your custom EMS job name here)
    AllowLegacyAlerts = false -- set true if you still route alerts through esx_ambulancejob events
}

-- Jobs allowed to go on duty. Set to your EMS job name (custom naming supported, e.g. 'ems').
Config.AllowedJobs = {
    'ems'
}

-- Duty points for ox_target. Add more entries with different coords to extend service points.
Config.DutyStations = {
    {
        label = 'Hospital Reception',
        coords = vec3(308.26, -595.21, 43.28),
        radius = 1.5
    },
    {
        label = 'Locker Room',
        coords = vec3(301.95, -599.34, 43.28),
        radius = 1.5
    }
}

-- Garage configuration. Add vehicles by appending to Vehicles with model + label.
Config.Garages = {
    {
        label = 'Pillbox Garage',
        coords = vec4(330.71, -573.6, 28.8, 250.0),
        spawn = vec4(332.38, -569.28, 28.8, 247.4),
        radius = 2.5,
        vehicles = {
            { model = 'ambulance', label = 'Ambulance Van' },
            { model = 'emslspd', label = 'Rapid Response SUV' },
            { model = 'emscar', label = 'Paramedic Sedan' }
        }
    }
}

-- Medical items. Ensure these exist in ox_inventory items table. See README for SQL samples.
Config.Items = {
    medicBag = 'medic_bag',
    bandage = 'med_bandage',
    painkillers = 'painkillers',
    ekg = 'med_ekg',
    adrenaline = 'med_adrenaline',
    -- Added: defibrillator item used for advanced revives
    defib = 'defib'
}

-- Treatment timings (in milliseconds)
Config.TreatmentTimes = {
    revive = 8000,
    -- NEW: healing (non-revive) action for injured but alive players
    heal = 4000,
    -- Added: defibrillator charge time
    defib = 6000,
    stabilizeLight = 2500,
    stabilizeMedium = 4500,
    stabilizeHeavy = 6500,
    painkillers = 2000,
    ekg = 2500
}

-- Healing values applied by treatments
Config.HealthAdjust = {
    revive = 200,
    -- NEW: healing amount for injured patients that are still conscious
    heal = 60,
    -- Added: health value used when reviving with the defibrillator
    defib = 200,
    bandageLight = 20,
    bandageMedium = 35,
    bandageHeavy = 50,
    painkillers = 15
}

-- Added: defibrillator behavior configuration
Config.Defib = {
    SuccessChance = 1.0, -- 1.0 = always succeed, set lower for chance-based revives
    FailNotify = 'Defibrillation fehlgeschlagen.',
    SuccessNotify = 'Patient stabilisiert (Defibrillator).'
}

-- NEW: Dispatch / tablet settings
Config.Dispatch = {
    Command = 'ems', -- chat command to open EMS tablet/dispatch
    EnableCommand = true,
    RequireOnDuty = true,
    -- NEW: manual distress key (hold/press while downed to send dispatch)
    PanicKey = 47, -- default: G key
    PanicKeyLabel = 'G', -- UI hint label
    AutoOnDeath = false, -- when false, player must press PanicKey to send dispatch
    OpenKey = 'F6', -- key binding for the leitstelle tablet
    AlertSound = { sound = 'TIMER_STOP', set = 'HUD_MINI_GAME_SOUNDSET' }
}

-- Maximum distance for targeting nearby patients
Config.PatientRange = 3.0

-- Livery index used for spawned vehicles
Config.VehicleLivery = 4

-- Whether to auto-enable all extras on spawned vehicles
Config.EnableAllExtras = true

-- Debug printing
Config.Debug = false
