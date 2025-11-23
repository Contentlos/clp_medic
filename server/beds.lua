-- NEW: hospital bed + locker + billing helpers
local ESX = exports['es_extended']:getSharedObject()

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

local function gradeAllowed(xPlayer, list)
    if not list or #list == 0 then return true end
    for _, grade in ipairs(list) do
        if xPlayer.job and xPlayer.job.grade == grade then
            return true
        end
    end
    return false
end

-- Locker access gives configured loadout
RegisterNetEvent('clp_medic:locker:request', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not isAllowedJob(src) then return end
    if not gradeAllowed(xPlayer, Config.Ranks.Locker) then
        TriggerClientEvent('esx:showNotification', src, 'Keine Berechtigung für den Spind.', 'error')
        return
    end

    for _, item in ipairs(Config.Lockers[1].loadout or {}) do
        exports.ox_inventory:AddItem(src, item.item, item.count or 1)
    end
    TriggerClientEvent('esx:showNotification', src, 'Ausrüstung entnommen.')
end)

-- Billing helper (optional)
RegisterNetEvent('clp_medic:billPatient', function(targetId)
    if not Config.Billing.Enabled then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not isAllowedJob(src) then return end
    if not gradeAllowed(xPlayer, Config.Ranks.Billing) then
        TriggerClientEvent('esx:showNotification', src, 'Keine Berechtigung zum Abrechnen.', 'error')
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        TriggerClientEvent('esx:showNotification', src, 'Patient nicht gefunden.', 'error')
        return
    end

    if Config.Billing.SocietyAccount and Config.Billing.SocietyAccount ~= '' then
        TriggerEvent('esx_billing:sendBill', targetId, src, Config.Billing.SocietyAccount, 'EMS Behandlung', Config.Billing.Amount)
    else
        TriggerEvent('esx_billing:sendBill', targetId, src, 'society_ems', 'EMS Behandlung', Config.Billing.Amount)
    end

    TriggerClientEvent('esx:showNotification', src, 'Rechnung erstellt.')
end)

-- Bed placement + auto-heal tick
local bedOccupants = {}

RegisterNetEvent('clp_medic:bed:place', function(targetId, bedIndex)
    local src = source
    if not isAllowedJob(src) then return end
    bedIndex = tonumber(bedIndex or 0)
    local bed = Config.HospitalBeds[bedIndex]
    if not bed then return end

    bedOccupants[bedIndex] = targetId
    TriggerClientEvent('clp_medic:bed:set', targetId, bed.coords, bed.autoHeal, bedIndex)
end)

RegisterNetEvent('clp_medic:bed:release', function(bedIndex)
    bedOccupants[bedIndex] = nil
end)
