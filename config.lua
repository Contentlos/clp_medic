Config = {}

Config.Compatibility = {
    UseAmbulanceJob = true,
    AllowLegacyAlerts = false
}

Config.AllowedJobs = {
    'ems'
}

Config.DutyStations = {
    {
        label = 'Hospital Reception',
        coords = vec3(1141.6531, -1537.7006, 35.3759),
        radius = 1.5
    },
    {
        label = 'Locker Room',
        coords = vec3(301.95, -599.34, 43.28),
        radius = 1.5
    }
}

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

Config.Items = {
    medicBag = 'medic_bag',
    bandage = 'bandage',
    painkillers = 'painkillers',
    ekg = 'ekg',
    adrenaline = 'med_adrenaline',
    defib = 'defib'
}

Config.TreatmentTimes = {
    revive = 8000,
    heal = 4000,
    defib = 6000,
    stabilizeLight = 2500,
    stabilizeMedium = 4500,
    stabilizeHeavy = 6500,
    painkillers = 2000,
    ekg = 2500
}

Config.HealthAdjust = {
    revive = 200,
    heal = 60,
    defib = 200,
    bandageLight = 20,
    bandageMedium = 35,
    bandageHeavy = 50,
    painkillers = 15
}

Config.Defib = {
    RequiresItem = true,
    AllowWithBag = true,
    ConsumeOnUse = false,
    SuccessChance = 1.0,
    FailNotify = 'Defibrillation fehlgeschlagen.',
    SuccessNotify = 'Patient stabilisiert (Defibrillator).'
}

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

Config.Dispatch = {
    Command = 'ems',
    EnableCommand = true,
    RequireOnDuty = true,
    PanicKey = 47,
    PanicKeyLabel = 'G',
    AutoOnDeath = false,
    OpenKey = 'F6',
    AlertSound = { sound = 'TIMER_STOP', set = 'HUD_MINI_GAME_SOUNDSET' },
    UnitStatuses = { 'available', 'en_route', 'on_scene', 'hospital', 'out_of_service' },
    SetWaypointOnAccept = true,
    DefaultPriority = 2
}

Config.PatientRange = 3.0

Config.VehicleLivery = 4
Config.EnableAllExtras = true

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

Config.Billing = {
    Enabled = false,
    Amount = 750,
    SocietyAccount = 'society_ems'
}

Config.Ranks = {
    DispatchControl = { 2, 3, 4 },
    Billing = { 1, 2, 3, 4 },
    Locker = { 0, 1, 2, 3, 4 }
}

Config.FlavorChecks = {
    { label = 'Puls prüfen', text = 'Du prüfst den Puls...', result = 'Puls ist schwach' },
    { label = 'Atmung prüfen', text = 'Du prüfst die Atmung...', result = 'Atmung ist flach' },
    { label = 'Pupillen prüfen', text = 'Du prüfst die Pupillen...', result = 'Pupillen reagieren langsam' }
}

Config.Debug = false
