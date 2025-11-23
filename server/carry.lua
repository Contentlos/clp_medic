-- Added: carry synchronization between medic and patient
local ESX = exports['es_extended']:getSharedObject()
local carryingPairs = {}

local function isAuthorizedMedic(src)
    if Config.Compatibility.UseAmbulanceJob then
        local xPlayer = ESX.GetPlayerFromId(src)
        local allowed = false
        if xPlayer and xPlayer.job then
            for _, job in ipairs(Config.AllowedJobs) do
                if xPlayer.job.name == job then
                    allowed = true
                    break
                end
            end
        end
        if not allowed then
            return false
        end
    end
    return Player(src).state.clp_medic_onDuty == true
end

RegisterNetEvent('clp_medic:requestCarry', function(targetId)
    local src = source
    if not targetId then return end
    if not isAuthorizedMedic(src) then
        TriggerClientEvent('esx:showNotification', src, 'Du bist nicht im Dienst.')
        return
    end

    carryingPairs[src] = targetId
    Player(src).state:set('clp_medic_carryingTarget', targetId, true)

    -- Sync carry start to both participants
    TriggerClientEvent('clp_medic:carryTarget', src, targetId)
    TriggerClientEvent('clp_medic:setCarried', targetId, src, true)
end)

RegisterNetEvent('clp_medic:stopCarry', function()
    local src = source
    local targetId = carryingPairs[src]

    TriggerClientEvent('clp_medic:stopCarry', src)

    if targetId then
        TriggerClientEvent('clp_medic:setCarried', targetId, src, false)
    end

    carryingPairs[src] = nil
    Player(src).state:set('clp_medic_carryingTarget', nil, true)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local targetId = carryingPairs[src]
    if targetId then
        TriggerClientEvent('clp_medic:setCarried', targetId, src, false)
    end
    carryingPairs[src] = nil
end)
