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

-- NEW: remove item and return success
local function removeItem(xPlayer, item)
    local removed = exports.ox_inventory:RemoveItem(xPlayer.source, item, 1)
    if removed == nil then return false end
    if type(removed) == 'boolean' then return removed end
    return removed > 0
end

-- NEW: supply helper to let medic bags act as a portable kit
local function ensureSupply(xPlayer, item, fromBag, missingMessage)
    if fromBag then
        if hasItem(xPlayer, Config.Items.medicBag) then return true end
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Dir fehlt die Medic Bag.', 'error')
        return false
    end

    if not hasItem(xPlayer, item) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, missingMessage or 'Material fehlt.')
        return false
    end
    return true
end

local function consumeSupply(xPlayer, item, fromBag)
    if fromBag then return end -- medic bag stays as reusable kit
    removeItem(xPlayer, item)
end

local function handleRevive(xPlayer, target, fromBag)
    if not isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist nicht bewusstlos (Revive nicht möglich).')
        return
    end

    if not ensureSupply(xPlayer, Config.Items.adrenaline, fromBag, 'Dir fehlt Adrenalin / Advanced Revive.') then
        return
    end

    consumeSupply(xPlayer, Config.Items.adrenaline, fromBag)
    TriggerClientEvent('clp_medic:applyEffect', target, 'revive')
end

local function handleBandage(xPlayer, target, tier, fromBag)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nutze Revive/Defib bei bewusstlosen Patienten.')
        return
    end

    if not ensureSupply(xPlayer, Config.Items.bandage, fromBag, 'Keine Bandagen dabei.') then
        return
    end

    consumeSupply(xPlayer, Config.Items.bandage, fromBag)
    TriggerClientEvent('clp_medic:applyEffect', target, ('bandage_%s'):format(tier))
end

local function handlePainkillers(xPlayer, target, fromBag)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist bewusstlos, nutze Revive/Defib.')
        return
    end

    if not ensureSupply(xPlayer, Config.Items.painkillers, fromBag, 'Keine Schmerzmittel dabei.') then
        return
    end

    consumeSupply(xPlayer, Config.Items.painkillers, fromBag)
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
local function handleHeal(xPlayer, target, fromBag)
    if isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Patient ist bewusstlos, nutze Revive/Defib.')
        return
    end

    if not ensureSupply(xPlayer, Config.Items.bandage, fromBag, 'Keine Bandagen dabei.') then
        return
    end

    consumeSupply(xPlayer, Config.Items.bandage, fromBag)
    TriggerClientEvent('clp_medic:applyEffect', target, 'heal')
end

-- Added: defibrillator revive
local function handleDefib(xPlayer, target)
    if not isTargetDowned(target) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Defibrillator nur bei bewusstlosen Patienten möglich.')
        return
    end

    if not ensureSupply(xPlayer, Config.Items.defib, false, 'Defibrillator fehlt.') then
        return
    end

    local removed = removeItem(xPlayer, Config.Items.defib)
    if not removed then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Defibrillator konnte nicht genutzt werden.', 'error')
        return
    end

    local successRoll = math.random(0, 100) / 100
    local succeeded = successRoll <= Config.Defib.SuccessChance

    TriggerClientEvent('clp_medic:defibResult', xPlayer.source, succeeded)

    if succeeded then
        TriggerClientEvent('clp_medic:updateEKGState', target, 'stable')
        TriggerClientEvent('clp_medic:applyEffect', target, 'defib')
    end
end

RegisterNetEvent('clp_medic:performTreatment', function(treatment, targetId, fromBag)
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
        handleRevive(xPlayer, targetId, fromBag)
    elseif treatment == 'heal' then
        handleHeal(xPlayer, targetId, fromBag)
    elseif treatment == 'bandage' or treatment == 'bandage_light' then
        handleBandage(xPlayer, targetId, 'light', fromBag)
    elseif treatment == 'bandage_medium' then
        handleBandage(xPlayer, targetId, 'medium', fromBag)
    elseif treatment == 'bandage_heavy' then
        handleBandage(xPlayer, targetId, 'heavy', fromBag)
    elseif treatment == 'painkillers' then
        handlePainkillers(xPlayer, targetId, fromBag)
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
