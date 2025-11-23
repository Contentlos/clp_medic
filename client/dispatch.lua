-- NEW: client-side dispatch / tablet UI integration
local ESX = exports['es_extended']:getSharedObject()
local tabletOpen = false

local function isAllowedJob()
    if not Config.Compatibility.UseAmbulanceJob then return true end
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        for _, job in ipairs(Config.AllowedJobs) do
            if playerData.job.name == job then
                return true
            end
        end
    end
    return false
end

local function canAccessDispatch()
    if not isAllowedJob() then return false end
    if Config.Dispatch.RequireOnDuty and not LocalPlayer.state.clp_medic_onDuty then
        return false
    end
    return true
end

local function openTablet(calls, units)
    if not canAccessDispatch() then
        ESX.ShowNotification('Kein Zugriff auf die Leitstelle.', 'error')
        return
    end

    tabletOpen = true
    SetNuiFocus(true, true)
    PlayTabletAnim(-1)
    SendNUIMessage({
        action = 'dispatchOpen',
        calls = calls or {},
        units = units or {}
    })
end

local function closeTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    StopMedicAnim()
    SendNUIMessage({ action = 'dispatchClose' })
end

RegisterNUICallback('dispatchClose', function(_, cb)
    closeTablet()
    cb('ok')
end)

RegisterNUICallback('dispatchStatus', function(data, cb)
    if data and data.id then
        TriggerServerEvent('clp_medic:dispatch:updateStatus', data.id, data.status or 'assigned')
        if data.status == 'assigned' and data.coords and Config.Dispatch.SetWaypointOnAccept then
            SetNewWaypoint(data.coords.x or 0.0, data.coords.y or 0.0)
        end
    end
    cb('ok')
end)

-- NEW: unit self-status change
RegisterNUICallback('unitStatus', function(data, cb)
    if data and data.status then
        TriggerServerEvent('clp_medic:dispatch:setUnitStatus', data.status)
    end
    cb('ok')
end)

RegisterNetEvent('clp_medic:dispatch:setCalls', function(calls, units)
    openTablet(calls, units)
end)

RegisterNetEvent('clp_medic:dispatch:update', function(calls, units)
    if tabletOpen then
        SendNUIMessage({ action = 'dispatchUpdate', calls = calls or {}, units = units or {} })
    end
end)

-- NEW: alert dispatch/EMS with visual + audio cue on new calls
RegisterNetEvent('clp_medic:dispatch:alert', function(callData)
    if not canAccessDispatch() then return end

    local sound = Config.Dispatch.AlertSound or {}
    if sound.sound then
        PlaySoundFrontend(-1, sound.sound, sound.set or 'HUD_MINI_GAME_SOUNDSET', true)
        CreateThread(function()
            for i = 1, 2 do
                Wait(600)
                PlaySoundFrontend(-1, sound.sound, sound.set or 'HUD_MINI_GAME_SOUNDSET', true)
            end
        end)
    end

    ESX.ShowNotification(('Neuer Notruf #%s: %s'):format(callData.id or '?', callData.reason or 'Einsatz'))

    if callData.coords then
        SetNewWaypoint(callData.coords.x or 0.0, callData.coords.y or 0.0)
    end

    SendNUIMessage({ action = 'dispatchPing', call = callData })
end)

if Config.Dispatch.EnableCommand then
    RegisterCommand(Config.Dispatch.Command, function()
        if not canAccessDispatch() then
            ESX.ShowNotification('Kein Zugriff auf die Leitstelle.', 'error')
            return
        end
        TriggerServerEvent('clp_medic:dispatch:request')
    end, false)

    -- NEW: bind leitstelle/tablet to Config.Dispatch.OpenKey (default F6)
    RegisterKeyMapping(Config.Dispatch.Command, 'EMS Leitstelle öffnen', 'keyboard', Config.Dispatch.OpenKey or 'F6')
end

-- Close tablet on resource stop to free focus
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if tabletOpen then
        closeTablet()
    end
end)
