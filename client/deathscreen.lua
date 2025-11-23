-- Added: death screen + EKG NUI handling
local isDowned = false
local currentState = 'stable'

local function sendUI(payload)
    SendNUIMessage(payload)
end

local function toggleDeathUI(state, ekgState)
    isDowned = state
    currentState = ekgState or currentState
    SetNuiFocus(false, false)
    sendUI({
        action = 'toggle',
        visible = state,
        status = currentState
    })
end

-- Added: update EKG state without forcing visibility
local function updateEKGState(state)
    currentState = state or currentState
    sendUI({
        action = 'setState',
        status = currentState
    })
end

-- Added: listen for ESX death to show overlay
RegisterNetEvent('esx:onPlayerDeath', function()
    -- NEW: mark player as downed and notify server/dispatch
    isDowned = true
    LocalPlayer.state:set('clp_medic_downed', true, true)
    TriggerServerEvent('clp_medic:playerDown', GetEntityCoords(PlayerPedId()))
    toggleDeathUI(true, 'flatline')
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
        end
        Wait(0)
    end
end)
