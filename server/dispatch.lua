-- NEW: EMS dispatch/leitstelle system
local ESX = exports['es_extended']:getSharedObject()

local dispatchCalls = {}
local callIndexByPlayer = {}
local nextCallId = 1

local function isAllowedJob(src)
    if not Config.Compatibility.UseAmbulanceJob then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return false end
    for _, job in ipairs(Config.AllowedJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

local function canAccessDispatch(src)
    if not isAllowedJob(src) then return false end
    if Config.Dispatch.RequireOnDuty and not Player(src).state.clp_medic_onDuty then
        return false
    end
    return true
end

local function serializeCalls()
    local list = {}
    for _, call in pairs(dispatchCalls) do
        list[#list+1] = call
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function broadcastCalls()
    local payload = serializeCalls()
    for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
        local src = xPlayer.source
        if canAccessDispatch(src) then
            TriggerClientEvent('clp_medic:dispatch:update', src, payload)
        end
    end
end

local function createCall(src, coords, reason)
    local id = nextCallId
    nextCallId = nextCallId + 1

    local xPlayer = src and ESX.GetPlayerFromId(src)
    local callerName = xPlayer and xPlayer.getName() or 'Unbekannt'
    local callData = {
        id = id,
        caller = src,
        callerName = callerName,
        coords = coords,
        reason = reason or 'Medizinischer Notruf',
        status = 'waiting',
        assigned = {}
    }

    dispatchCalls[id] = callData
    if src then
        callIndexByPlayer[src] = id
    end
    broadcastCalls()
end

local function updateCallStatus(src, callId, status)
    local call = dispatchCalls[callId]
    if not call then return end

    call.status = status or call.status
    if src then
        local xPlayer = ESX.GetPlayerFromId(src)
        local unit = xPlayer and xPlayer.getName() or ('Unit %s'):format(src)
        call.assigned[unit] = status
    end
    broadcastCalls()
end

RegisterNetEvent('clp_medic:dispatch:request', function()
    local src = source
    if not canAccessDispatch(src) then
        TriggerClientEvent('esx:showNotification', src, 'Kein Zugriff auf die Leitstelle.')
        return
    end

    TriggerClientEvent('clp_medic:dispatch:setCalls', src, serializeCalls())
end)

RegisterNetEvent('clp_medic:dispatch:updateStatus', function(callId, status)
    local src = source
    if not canAccessDispatch(src) then
        TriggerClientEvent('esx:showNotification', src, 'Kein Zugriff auf die Leitstelle.')
        return
    end
    updateCallStatus(src, callId, status)
end)

-- NEW: automatic dispatch for downed players
RegisterNetEvent('clp_medic:playerDown', function(coords)
    local src = source
    Player(src).state:set('clp_medic_downed', true, true)

    if coords then
        coords = { x = coords.x, y = coords.y, z = coords.z }
    end

    createCall(src, coords, 'Bewusstloser Spieler')
end)

RegisterNetEvent('clp_medic:playerRevived', function()
    local src = source
    Player(src).state:set('clp_medic_downed', false, true)

    local callId = callIndexByPlayer[src]
    if callId then
        updateCallStatus(nil, callId, 'completed')
        callIndexByPlayer[src] = nil
    end
end)

-- Command-based dispatch creation
if Config.Dispatch.EnableCommand then
    RegisterCommand(Config.Dispatch.Command, function(src)
        if src == 0 then return end
        local ped = GetPlayerPed(src)
        if not DoesEntityExist(ped) then return end
        local coords = GetEntityCoords(ped)
        createCall(src, { x = coords.x, y = coords.y, z = coords.z }, 'Leitstelle: Spieler hat einen Einsatz angefordert')
    end, false)
end

AddEventHandler('playerDropped', function()
    local src = source
    local callId = callIndexByPlayer[src]
    if callId and dispatchCalls[callId] then
        dispatchCalls[callId].status = 'completed'
        callIndexByPlayer[src] = nil
        broadcastCalls()
    end
end)
