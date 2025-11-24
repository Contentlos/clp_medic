-- NEW: shared EMS animation helpers

local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Play a configured animation preset from Config.Animations
function PlayMedicAnim(preset, duration)
    local data = Config.Animations[preset]
    if not data then return end
    loadDict(data.dict)
    TaskPlayAnim(PlayerPedId(), data.dict, data.clip, 8.0, -8.0, duration or -1, data.flag or 49, 0.0, false, false, false)
end

-- Stop current player animation
function StopMedicAnim()
    ClearPedTasks(PlayerPedId())
end

-- Play scenario helper
function PlayMedicScenario(scenario, duration)
    TaskStartScenarioInPlace(PlayerPedId(), scenario, 0, true)
    if duration and duration > 0 then
        Wait(duration)
        ClearPedTasks(PlayerPedId())
    end
end

-- Convenience wrappers for common flows
function PlayBagAnim(duration)
    PlayMedicAnim('Bag', duration)
end

function PlayVitalsAnim(duration)
    PlayMedicAnim('Vitals', duration)
end

function PlayBandageAnim(duration)
    PlayMedicAnim('Bandage', duration)
end

function PlayCPR2Anim(duration)
    PlayMedicAnim('CPR2', duration)
end

function PlayCPRPumpAnim(duration)
    PlayMedicAnim('CPR_PUMP', duration)
end

function PlayCarryAnim()
    PlayMedicAnim('Carry', -1)
end

function PlayPlaceAnim(duration)
    PlayMedicAnim('Place', duration)
end

function PlayTabletAnim(duration)
    PlayMedicAnim('Tablet', duration)
end

function PlayFlavorAnim(duration)
    PlayMedicAnim('Flavor', duration)
end
