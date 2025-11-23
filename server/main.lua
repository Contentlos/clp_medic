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
-- NEW: safe wrapper for ox_inventory RegisterUsableItem to handle older versions
local function safeRegisterUsableItem(name, handler)
    local ok = pcall(function()
        exports.ox_inventory:RegisterUsableItem(name, handler)
    end)

    if not ok then
        TriggerEvent('ox_inventory:RegisterUsableItem', name, function(event, item, inventory)
            handler(event, item, inventory)
        end)
    end
end

CreateThread(function()
    safeRegisterUsableItem(Config.Items.medicBag, function(event, item, inventory)
        local src = inventory.id or source
        TriggerClientEvent('clp_medic:openMedicBag', src)
    end)

    -- Added: register defibrillator usable item
    safeRegisterUsableItem(Config.Items.defib, function(event, item, inventory)
        local src = inventory.id or source
        TriggerClientEvent('clp_medic:useDefib', src)
    end)
end)

-- NEW: spawn garage vehicles server-side to avoid OneSync distance errors
RegisterNetEvent('clp_medic:spawnGarageVehicle', function(data)
    local src = source
    if not data or not data.model or not data.spawn then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if Config.Compatibility.UseAmbulanceJob then
        local allowed = false
        for _, job in ipairs(Config.AllowedJobs) do
            if xPlayer.job and xPlayer.job.name == job then
                allowed = true
                break
            end
        end
        if not allowed then return end
    end

    local spawnCoords = vec3(data.spawn.x, data.spawn.y, data.spawn.z)

    local function finalize(vehicle)
        if not vehicle then return end
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleNumberPlateText(vehicle, ('MED%s'):format(math.random(100, 999)))
        SetVehicleLivery(vehicle, Config.VehicleLivery)

        if Config.EnableAllExtras then
            for extra = 0, 20 do
                if DoesExtraExist(vehicle, extra) then
                    SetVehicleExtra(vehicle, extra, 0)
                end
            end
        end

        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        SetNetworkIdCanMigrate(netId, true)
        TriggerClientEvent('clp_medic:garageVehicleSpawned', src, netId)
    end

    if ESX.OneSync and ESX.OneSync.SpawnVehicle then
        ESX.OneSync.SpawnVehicle(data.model, spawnCoords, data.spawn.w, finalize)
    else
        local vehicle = CreateVehicle(data.model, spawnCoords.x, spawnCoords.y, spawnCoords.z, data.spawn.w, true, true)
        finalize(vehicle)
    end
end)
