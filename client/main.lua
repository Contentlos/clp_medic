local ESX = exports['es_extended']:getSharedObject()
local onDuty = false
local dutyZones = {}

local function debugPrint(...)
    if Config.Debug then
        print('[clp_medic]', ...)
    end
end

local function isAllowedJob()
    if not Config.Compatibility.UseAmbulanceJob then return true end
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then return false end

    for _, job in ipairs(Config.AllowedJobs) do
        if playerData.job.name == job then
            return true
        end
    end
    return false
end

local function registerDutyZones()
    for _, zone in ipairs(Config.DutyStations) do
        local id = ('clp_medic:duty:%s'):format(zone.label)
        dutyZones[id] = exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = zone.radius or 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = id,
                    icon = 'fa-solid fa-user-doctor',
                    label = ('%s - %s'):format(zone.label, onDuty and 'Off Duty' or 'On Duty'),
                    distance = 2.0,
                    onSelect = function()
                        if not isAllowedJob() then
                            ESX.ShowNotification('Du bist nicht als Medic eingestellt.', 'error')
                            return
                        end
                        TriggerServerEvent('clp_medic:toggleDuty')
                    end
                }
            }
        })
    end
end

local function updateDutyZoneLabels()
    for id, handle in pairs(dutyZones) do
        exports.ox_target:removeZone(handle)
    end
    dutyZones = {}
    registerDutyZones()
end

RegisterNetEvent('clp_medic:setDuty', function(state)
    onDuty = state
    ESX.ShowNotification(state and 'Du bist jetzt im Dienst.' or 'Du bist jetzt außer Dienst.')
    LocalPlayer.state:set('clp_medic_onDuty', state, true)
    updateDutyZoneLabels()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, handle in pairs(dutyZones) do
        exports.ox_target:removeZone(handle)
    end
end)

CreateThread(function()
    registerDutyZones()
    TriggerServerEvent('clp_medic:requestDuty')
end)

-- Check if a target is within range
local function getClosestPlayer()
    local closestPlayer, distance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and distance <= Config.PatientRange then
        return GetPlayerServerId(closestPlayer)
    end
    return nil
end

-- NEW: helper to check if a ped is downed
local function isPedDowned(entity)
    return IsPedDeadOrDying(entity, true)
end

-- Player interaction options
local function canUseMedicActions()
    return onDuty and isAllowedJob()
end

exports.ox_target:addGlobalPlayer({
    {
        name = 'clp_medic:revive',
        icon = 'fa-solid fa-heart-pulse',
        label = 'Revive',
        canInteract = function(entity)
            return canUseMedicActions() and isPedDowned(entity)
        end,
        onSelect = function(data)
            TriggerEvent('clp_medic:handleTreatment', 'revive', data.entity)
        end
    },
    -- NEW: healing option for injured but alive players
    {
        name = 'clp_medic:heal',
        icon = 'fa-solid fa-syringe',
        label = 'Heilen',
        canInteract = function(entity)
            return canUseMedicActions() and not isPedDowned(entity) and (GetEntityHealth(entity) < 200)
        end,
        onSelect = function(data)
            TriggerEvent('clp_medic:handleTreatment', 'heal', data.entity)
        end
    },
    {
        name = 'clp_medic:stabilize',
        icon = 'fa-solid fa-bandage',
        label = 'Bandagieren',
        canInteract = function(entity)
            return canUseMedicActions() and not isPedDowned(entity)
        end,
        onSelect = function(data)
            TriggerEvent('clp_medic:handleTreatment', 'bandage', data.entity)
        end
    },
    {
        name = 'clp_medic:ekg',
        icon = 'fa-solid fa-notes-medical',
        label = 'EKG prüfen',
        canInteract = canUseMedicActions,
        onSelect = function(data)
            TriggerEvent('clp_medic:handleTreatment', 'ekg', data.entity)
        end
    }
})

-- Used by medic bag to open treatment menu
RegisterNetEvent('clp_medic:openMedicBag', function()
    if not canUseMedicActions() then
        ESX.ShowNotification('Du bist nicht im Dienst.', 'error')
        return
    end

    local playerId = getClosestPlayer()
    if not playerId then
        ESX.ShowNotification('Kein Patient in der Nähe.', 'error')
        return
    end

    lib.registerContext({
        id = 'clp_medic:bag_menu',
        title = 'Medic Bag',
        options = {
            { title = 'Revive', description = 'Adrenalin einsetzen, um einen Patienten zu beleben', event = 'clp_medic:startBagAction', args = { type = 'revive', target = playerId } },
            -- NEW: healing action for conscious patients
            { title = 'Heilen', description = 'Patienten ohne Bewusstlosigkeit versorgen', event = 'clp_medic:startBagAction', args = { type = 'heal', target = playerId } },
            { title = 'Bandage - leicht', description = 'Kleine Verletzungen versorgen', event = 'clp_medic:startBagAction', args = { type = 'bandage_light', target = playerId } },
            { title = 'Bandage - mittel', description = 'Mittlere Verletzungen versorgen', event = 'clp_medic:startBagAction', args = { type = 'bandage_medium', target = playerId } },
            { title = 'Bandage - schwer', description = 'Schwere Verletzungen versorgen', event = 'clp_medic:startBagAction', args = { type = 'bandage_heavy', target = playerId } },
            { title = 'Painkillers', description = 'Schmerzmittel verabreichen', event = 'clp_medic:startBagAction', args = { type = 'painkillers', target = playerId } },
            { title = 'EKG Check', description = 'Herzrhythmus prüfen', event = 'clp_medic:startBagAction', args = { type = 'ekg', target = playerId } }
        }
    })

    lib.showContext('clp_medic:bag_menu')
end)

RegisterNetEvent('clp_medic:startBagAction', function(data)
    TriggerEvent('clp_medic:handleTreatment', data.type, data.target)
end)

-- Client-side handler for starting treatments
RegisterNetEvent('clp_medic:handleTreatment', function(treatment, entity)
    if not canUseMedicActions() then
        ESX.ShowNotification('Du bist nicht im Dienst.', 'error')
        return
    end

    local targetId
    if type(entity) == 'number' then
        if NetworkIsPlayerActive(entity) then
            targetId = GetPlayerServerId(entity)
        else
            targetId = entity -- already a server id from ox_target
        end
    elseif entity then
        targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
    end

    if not targetId then
        ESX.ShowNotification('Kein Patient ausgewählt.', 'error')
        return
    end

    local animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local anim = 'machinic_loop_mechandplayer'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    local duration = Config.TreatmentTimes.stabilizeLight
    if treatment == 'revive' then
        duration = Config.TreatmentTimes.revive
    elseif treatment == 'heal' then
        duration = Config.TreatmentTimes.heal
    elseif treatment == 'ekg' then
        duration = Config.TreatmentTimes.ekg
    elseif treatment == 'bandage' or treatment == 'bandage_light' then
        duration = Config.TreatmentTimes.stabilizeLight
    elseif treatment == 'bandage_medium' then
        duration = Config.TreatmentTimes.stabilizeMedium
    elseif treatment == 'bandage_heavy' then
        duration = Config.TreatmentTimes.stabilizeHeavy
    elseif treatment == 'painkillers' then
        duration = Config.TreatmentTimes.painkillers
    end

    local success = lib.progressCircle({
        duration = duration,
        position = 'bottom',
        label = 'Behandlung läuft...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = animDict,
            clip = anim
        }
    })

    ClearPedTasks(PlayerPedId())
    if not success then return end

    TriggerServerEvent('clp_medic:performTreatment', treatment, targetId)
end)

-- Client-side revival/healing applied to the patient
RegisterNetEvent('clp_medic:applyEffect', function(effect)
    local ped = PlayerPedId()
    if effect == 'revive' then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, Config.HealthAdjust.revive)
        ClearPedBloodDamage(ped)
        ESX.ShowNotification('Du wurdest wiederbelebt.')
        LocalPlayer.state:set('clp_medic_downed', false, true)
        TriggerServerEvent('clp_medic:playerRevived')
        -- Added: ensure death UI/EKG resets when revived
        TriggerEvent('clp_medic:updateEKGState', 'stable')
        TriggerEvent('clp_medic:toggleDeathUI', false, 'stable')
    elseif effect == 'defib' then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, Config.HealthAdjust.defib)
        ClearPedBloodDamage(ped)
        ESX.ShowNotification('Du wurdest durch Defibrillation belebt.')
        LocalPlayer.state:set('clp_medic_downed', false, true)
        TriggerServerEvent('clp_medic:playerRevived')
        -- Added: ensure EKG reflects stabilization
        TriggerEvent('clp_medic:updateEKGState', 'stable')
        TriggerEvent('clp_medic:toggleDeathUI', false, 'stable')
    elseif effect == 'heal' then
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + Config.HealthAdjust.heal))
        ESX.ShowNotification('Behandlung abgeschlossen (Heilen).')
    elseif effect == 'bandage_light' then
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + Config.HealthAdjust.bandageLight))
        ESX.ShowNotification('Leichte Wunden wurden versorgt.')
    elseif effect == 'bandage_medium' then
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + Config.HealthAdjust.bandageMedium))
        ESX.ShowNotification('Mittlere Wunden wurden versorgt.')
    elseif effect == 'bandage_heavy' then
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + Config.HealthAdjust.bandageHeavy))
        ESX.ShowNotification('Schwere Wunden wurden versorgt.')
    elseif effect == 'painkillers' then
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + Config.HealthAdjust.painkillers))
        ESX.ShowNotification('Schmerzmittel verabreicht.')
    end
end)

-- Vitals check on target player
RegisterNetEvent('clp_medic:checkVitals', function(medicId)
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local status = 'Stabil'
    if health < 100 then
        status = 'Kritisch'
    elseif health < 150 then
        status = 'Instabil'
    end

    TriggerServerEvent('clp_medic:returnVitals', medicId, {
        health = health,
        status = status
    })
end)

RegisterNetEvent('clp_medic:receiveVitals', function(data)
    ESX.ShowNotification(('Patientenstatus: %s | Herzfrequenz: ~b~%s~s~'):format(data.status, data.health))
end)

-- Init notification for duty state when joining
RegisterNetEvent('clp_medic:initialDuty', function(state)
    onDuty = state
    LocalPlayer.state:set('clp_medic_onDuty', state, true)
    updateDutyZoneLabels()
end)
