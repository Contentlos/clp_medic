Config = {}

-- Toggle legacy compatibility. This does not hard-require esx_ambulancejob,
-- but lets you keep its job name/grades active during the transition.
Config.Compatibility = {
    UseAmbulanceJob = true, -- require job name to be 'ambulance'
    AllowLegacyAlerts = false -- set true if you still route alerts through esx_ambulancejob events
}

-- Jobs allowed to go on duty. Add additional job names if you want multiple medical groups.
Config.AllowedJobs = {
    'ambulance'
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
    adrenaline = 'med_adrenaline'
}

-- Treatment timings (in milliseconds)
Config.TreatmentTimes = {
    revive = 8000,
    stabilizeLight = 2500,
    stabilizeMedium = 4500,
    stabilizeHeavy = 6500,
    painkillers = 2000,
    ekg = 2500
}

-- Healing values applied by treatments
Config.HealthAdjust = {
    revive = 200,
    bandageLight = 20,
    bandageMedium = 35,
    bandageHeavy = 50,
    painkillers = 15
}

-- Maximum distance for targeting nearby patients
Config.PatientRange = 3.0

-- Livery index used for spawned vehicles
Config.VehicleLivery = 4

-- Whether to auto-enable all extras on spawned vehicles
Config.EnableAllExtras = true

-- Debug printing
Config.Debug = false
