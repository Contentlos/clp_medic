local ESX = exports['es_extended']:getSharedObject()

-- NEW: EMS job helper (respects custom EMS job naming)
local function isAllowedJob(xPlayer)
    if not Config.Compatibility.UseAmbulanceJob then return true end
    for _, job in ipairs(Config.AllowedJobs) do
        if xPlayer.job and xPlayer.job.name == job then
            return true
        end
    end
    return false
end

local function isTargetDowned(targetId)
    local playerState = Player(targetId) and Player(targetId).state
    return playerState and playerState.clp_medic_downed == true
end

local function hasItem(xPlayer, item)
    local count = exports.ox_inventory:Search(xPlayer.source, 'count', item)
    return (count or 0) > 0
end

local function removeItem(xPlayer, item)
    exports.ox_inventory:RemoveItem(xPlayer.source, item, 1)
end

local function handleRevive(xPlayer, target)
    if not isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist nicht bewusstlos (Revive nicht möglich).')
        return
    end

    if not hasItem(xPlayer, Config.Items.adrenaline) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Dir fehlt Adrenalin / Advanced Revive.')
        return
    end

    removeItem(xPlayer, Config.Items.adrenaline)
    TriggerClientEvent('clp_medic:applyEffect', target, 'revive')
end

local function handleBandage(xPlayer, target, tier)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nutze Revive/Defib bei bewusstlosen Patienten.')
        return
    end

    if not hasItem(xPlayer, Config.Items.bandage) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Keine Bandagen dabei.')
        return
    end

    removeItem(xPlayer, Config.Items.bandage)
    TriggerClientEvent('clp_medic:applyEffect', target, ('bandage_%s'):format(tier))
end

local function handlePainkillers(xPlayer, target)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist bewusstlos, nutze Revive/Defib.')
        return
    end

    if not hasItem(xPlayer, Config.Items.painkillers) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Keine Schmerzmittel dabei.')
        return
    end

    removeItem(xPlayer, Config.Items.painkillers)
    TriggerClientEvent('clp_medic:applyEffect', target, 'painkillers')
end

local function handleEKG(xPlayer, target)
    if not hasItem(xPlayer, Config.Items.ekg) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'EKG-Gerät fehlt.')
        return
    end

    TriggerClientEvent('clp_medic:checkVitals', target, xPlayer.source)
end

-- NEW: healing flow (injured but alive patients)
local function handleHeal(xPlayer, target)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist bewusstlos, nutze Revive/Defib.')
        return
    end

    if not hasItem(xPlayer, Config.Items.bandage) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Keine Bandagen dabei.')
        return
    end

    removeItem(xPlayer, Config.Items.bandage)
    TriggerClientEvent('clp_medic:applyEffect', target, 'heal')
end

-- Added: defibrillator revive
local function handleDefib(xPlayer, target)
    if not isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Defibrillator nur bei bewusstlosen Patienten möglich.')
        return
    end

    if not hasItem(xPlayer, Config.Items.defib) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Defibrillator fehlt.')
        return
    end

    removeItem(xPlayer, Config.Items.defib)

    local successRoll = math.random(0, 100) / 100
    local succeeded = successRoll <= Config.Defib.SuccessChance

    TriggerClientEvent('clp_medic:defibResult', xPlayer.source, succeeded)

    if succeeded then
        TriggerClientEvent('clp_medic:updateEKGState', target, 'stable')
        TriggerClientEvent('clp_medic:applyEffect', target, 'defib')
    end
end

RegisterNetEvent('clp_medic:performTreatment', function(treatment, targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not isAllowedJob(xPlayer) then
        TriggerClientEvent('esx:showNotification', src, 'Du bist nicht berechtigt.')
        return
    end

    if not Player(src).state.clp_medic_onDuty then
        TriggerClientEvent('esx:showNotification', src, 'Du bist nicht im Dienst.')
        return
    end

    if treatment == 'revive' then
        handleRevive(xPlayer, targetId)
    elseif treatment == 'heal' then
        handleHeal(xPlayer, targetId)
    elseif treatment == 'bandage' or treatment == 'bandage_light' then
        handleBandage(xPlayer, targetId, 'light')
    elseif treatment == 'bandage_medium' then
        handleBandage(xPlayer, targetId, 'medium')
    elseif treatment == 'bandage_heavy' then
        handleBandage(xPlayer, targetId, 'heavy')
    elseif treatment == 'painkillers' then
        handlePainkillers(xPlayer, targetId)
    elseif treatment == 'ekg' then
        handleEKG(xPlayer, targetId)
    elseif treatment == 'defib' then
        handleDefib(xPlayer, targetId)
    end
end)

-- Added: standalone defib trigger (usable item flow)
RegisterNetEvent('clp_medic:performDefib', function(targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not isAllowedJob(xPlayer) then
        TriggerClientEvent('esx:showNotification', src, 'Du bist nicht berechtigt.')
        return
    end

    if not Player(src).state.clp_medic_onDuty then
        TriggerClientEvent('esx:showNotification', src, 'Du bist nicht im Dienst.')
        return
    end

    handleDefib(xPlayer, targetId)
end)

RegisterNetEvent('clp_medic:returnVitals', function(medicId, vitals)
    TriggerClientEvent('clp_medic:receiveVitals', medicId, vitals)
end)
