-- Added: carrying logic for downed players
local ESX = exports['es_extended']:getSharedObject()
local carrying = false
local carriedTargetId = nil
local beingCarried = false
local carrierId = nil

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function stopCarry()
    carrying = false
    carriedTargetId = nil
    ClearPedTasks(PlayerPedId())
    LocalPlayer.state:set('clp_medic_carrying', false, true)
end

local function detachFromCarrier()
    beingCarried = false
    carrierId = nil
    DetachEntity(PlayerPedId(), true, false)
    ClearPedTasks(PlayerPedId())
    LocalPlayer.state:set('clp_medic_carried', false, true)
end

-- Added: start carry animation for medic
RegisterNetEvent('clp_medic:carryTarget', function(targetId)
    carrying = true
    carriedTargetId = targetId
    LocalPlayer.state:set('clp_medic_carrying', true, true)

    local dict = 'missfinale_c2mcs_1'
    local clip = 'fin_c2_mcs_1_camman'
    loadAnimDict(dict)
    TaskPlayAnim(PlayerPedId(), dict, clip, 8.0, -8.0, -1, 49, 0, false, false, false)
end)

-- Added: target gets attached/detached to carrier
RegisterNetEvent('clp_medic:setCarried', function(medicId, state)
    local ped = PlayerPedId()
    if state then
        beingCarried = true
        carrierId = medicId
        LocalPlayer.state:set('clp_medic_carried', true, true)

        local carrier = GetPlayerFromServerId(medicId)
        local carrierPed = carrier ~= -1 and GetPlayerPed(carrier) or nil
        if carrierPed and carrierPed ~= 0 then
            loadAnimDict('nm')
            TaskPlayAnim(ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
            AttachEntityToEntity(ped, carrierPed, 0, 0.27, 0.15, 0.63, 200.0, 200.0, 180.0, false, false, false, false, 2, true)
        end
    else
        detachFromCarrier()
    end
end)

-- Added: release for medic
RegisterNetEvent('clp_medic:stopCarry', function()
    stopCarry()
end)

-- Added: provide ox_target interactions for carrying
exports.ox_target:addGlobalPlayer({
    {
        name = 'clp_medic:carry:start',
        icon = 'fa-solid fa-person-carry-box',
        label = 'Patient tragen',
        canInteract = function(entity)
            if not LocalPlayer.state.clp_medic_onDuty then return false end
            if LocalPlayer.state.clp_medic_carrying then return false end
            return IsPedDeadOrDying(entity, true)
        end,
        onSelect = function(data)
            local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            if targetId then
                TriggerServerEvent('clp_medic:requestCarry', targetId)
            end
        end
    },
    {
        name = 'clp_medic:carry:stop',
        icon = 'fa-solid fa-person-walking-arrow-loop-left',
        label = 'Patient absetzen',
        canInteract = function()
            return LocalPlayer.state.clp_medic_carrying == true
        end,
        onSelect = function()
            TriggerServerEvent('clp_medic:stopCarry')
        end
    }
})

-- Added: clean up on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if carrying then
        stopCarry()
    end
    if beingCarried then
        detachFromCarrier()
    end
end)
