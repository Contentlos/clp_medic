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
    -- NEW: treat defib as tool/ability (not consumed) and gate by equipment
    RequiresItem = true, -- requires Config.Items.defib in inventory (or medic bag if AllowWithBag)
    AllowWithBag = true, -- allow medic bag to count as equipment carrier for defib
    ConsumeOnUse = false, -- set true if you want to remove the defib item per use
    SuccessChance = 1.0, -- 1.0 = always succeed, set lower for chance-based revives
    FailNotify = 'Defibrillation fehlgeschlagen.',
    SuccessNotify = 'Patient stabilisiert (Defibrillator).'
}

-- NEW: animation presets for immersive EMS actions
Config.Animations = {
    CPR2 = { dict = 'missheistfbi3b_ig8_2', clip = 'cpr2_idle', flag = 1 },
    CPR_PUMP = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest', flag = 49 },
    Vitals = { dict = 'amb@medic@standing@timeofdeath@enter', clip = 'enter', flag = 49 },
    Bag = { dict = 'amb@medic@standing@tendtodead@base', clip = 'base', flag = 49 },
    Bandage = { dict = 'amb@medic@standing@bandage@base', clip = 'base', flag = 49 },
    Tablet = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', clip = 'idle_a', flag = 49 },
    Carry = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_camman', flag = 49 },
    Place = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
    Flavor = { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 49 }
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
    AlertSound = { sound = 'TIMER_STOP', set = 'HUD_MINI_GAME_SOUNDSET' },
    -- NEW: unit status list and whether to set waypoints when accepting a call
    UnitStatuses = { 'available', 'en_route', 'on_scene', 'hospital', 'out_of_service' },
    SetWaypointOnAccept = true,
    DefaultPriority = 2
}

-- Maximum distance for targeting nearby patients
Config.PatientRange = 3.0

-- Livery index used for spawned vehicles
Config.VehicleLivery = 4

-- Whether to auto-enable all extras on spawned vehicles
Config.EnableAllExtras = true

-- NEW: hospital beds / treatment spots
Config.HospitalBeds = {
    {
        label = 'ICU Bed 1',
        coords = vec4(313.53, -583.05, 43.28, 68.0),
        autoHeal = { enabled = true, interval = 3500, amount = 5 }
    },
    {
        label = 'ICU Bed 2',
        coords = vec4(315.13, -585.3, 43.28, 68.0),
        autoHeal = { enabled = true, interval = 3500, amount = 5 }
    }
}

-- NEW: EMS locker / supply points
Config.Lockers = {
    {
        label = 'EMS Locker',
        coords = vec3(301.0, -599.0, 43.28),
        radius = 1.5,
        loadout = {
            { item = 'medic_bag', count = 1 },
            { item = 'med_bandage', count = 10 },
            { item = 'painkillers', count = 5 },
            { item = 'defib', count = 1 }
        }
    }
}

-- NEW: optional billing
Config.Billing = {
    Enabled = false,
    Amount = 750,
    SocietyAccount = 'society_ems'
}

-- NEW: grade-based permissions (set to your EMS grades)
Config.Ranks = {
    DispatchControl = { 2, 3, 4 },
    Billing = { 1, 2, 3, 4 },
    Locker = { 0, 1, 2, 3, 4 }
}

-- NEW: roleplay flavor actions (ox_target menu entries)
Config.FlavorChecks = {
    { label = 'Puls prüfen', text = 'Du prüfst den Puls...', result = 'Puls ist schwach' },
    { label = 'Atmung prüfen', text = 'Du prüfst die Atmung...', result = 'Atmung ist flach' },
    { label = 'Pupillen prüfen', text = 'Du prüfst die Pupillen...', result = 'Pupillen reagieren langsam' }
}

-- Debug printing
Config.Debug = false
