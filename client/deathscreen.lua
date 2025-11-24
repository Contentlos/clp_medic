-- Added: death screen + EKG NUI handling (cyber style)
local isDowned = false
local dispatchSent = false
local currentState = 'stable'
local lastCoords

local function sendUI(payload)
    SendNUIMessage(payload)
end

local function toggleDeathUI(state, ekgState)
    isDowned = state
    currentState = ekgState or currentState
    SetNuiFocus(false, false)
    sendUI({
        action = state and 'showDeathscreen' or 'hideDeathscreen',
        status = currentState,
        panicLabel = Config.Dispatch.PanicKeyLabel
    })
end

-- Added: update EKG state without forcing visibility
local function updateEKGState(state)
    currentState = state or currentState
    sendUI({
        action = 'setEKGState',
        status = currentState
    })
end

-- Added: listen for ESX death to show overlay
RegisterNetEvent('esx:onPlayerDeath', function()
    -- NEW: mark player as downed and notify server/dispatch
    isDowned = true
    LocalPlayer.state:set('clp_medic_downed', true, true)
    dispatchSent = false
    lastCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('clp_medic:playerDown', lastCoords)
    toggleDeathUI(true, 'unstable')
    SetTimeout(1000, function()
        if isDowned then
            sendUI({ action = 'setEKGState', status = 'flatline' })
        end
    end)
end)

-- Added: allow other scripts to explicitly toggle the death UI
RegisterNetEvent('clp_medic:toggleDeathUI', function(state, ekgState)
    toggleDeathUI(state, ekgState)
end)

-- Added: update EKG state externally
RegisterNetEvent('clp_medic:updateEKGState', function(state)
    updateEKGState(state)
end)

-- Added: hide overlay on spawn
AddEventHandler('playerSpawned', function()
    isDowned = false
    dispatchSent = false
    LocalPlayer.state:set('clp_medic_downed', false, true)
    TriggerServerEvent('clp_medic:playerRevived')
    toggleDeathUI(false, 'stable')
end)

-- Added: simple control lock when downed to match overlay state
CreateThread(function()
    while true do
        if isDowned then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, Config.Dispatch.PanicKey, true)

            -- NEW: manual distress trigger on panic key (Config.Dispatch.PanicKey, default G)
            if not dispatchSent and IsControlJustReleased(0, Config.Dispatch.PanicKey) then
                dispatchSent = true
                local coords = lastCoords or GetEntityCoords(PlayerPedId())
                TriggerServerEvent('clp_medic:dispatch:panic', coords)
                sendUI({ action = 'dispatchSent' })
            end
        end
        Wait(0)
    end
end)
