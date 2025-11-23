local ESX = exports['es_extended']:getSharedObject()
local dutyPlayers = {}

local function isAllowedJob(xPlayer)
    if not Config.Compatibility.UseAmbulanceJob then return true end
    for _, job in ipairs(Config.AllowedJobs) do
        if xPlayer.job and xPlayer.job.name == job then
            return true
        end
    end
    return false
end

local function setDuty(source, state)
    dutyPlayers[source] = state
    TriggerClientEvent('clp_medic:setDuty', source, state)
    local player = ESX.GetPlayerFromId(source)
    if player then
        player.set('clp_medic_onDuty', state)
    end
    TriggerClientEvent('clp_medic:initialDuty', source, state)
    Player(source).state:set('clp_medic_onDuty', state, true)
end

RegisterNetEvent('clp_medic:toggleDuty', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not isAllowedJob(xPlayer) then
        TriggerClientEvent('esx:showNotification', src, 'Du hast keinen Medic-Job.')
        return
    end

    local newState = not dutyPlayers[src]
    setDuty(src, newState)
end)

RegisterNetEvent('clp_medic:requestDuty', function()
    local src = source
    setDuty(src, dutyPlayers[src] or false)
end)

AddEventHandler('playerDropped', function()
    dutyPlayers[source] = nil
end)

-- Register usable medic bag
CreateThread(function()
    exports.ox_inventory:RegisterUsableItem(Config.Items.medicBag, function(event, item, inventory)
        local src = inventory.id
        TriggerClientEvent('clp_medic:openMedicBag', src)
    end)

    -- Added: register defibrillator usable item
    exports.ox_inventory:RegisterUsableItem(Config.Items.defib, function(event, item, inventory)
        TriggerClientEvent('clp_medic:useDefib', inventory.id)
    end)
end)
