-- Added: defibrillator handling (tool-based)
local ESX = exports['es_extended']:getSharedObject()

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

RegisterNetEvent('clp_medic:startDefib', function(targetId, fromBag)
    if not LocalPlayer.state.clp_medic_onDuty or not isAllowedJob() then
        ESX.ShowNotification('Du bist nicht im Dienst.', 'error')
        return
    end

    local targetIdx = GetPlayerFromServerId(targetId)
    if targetIdx == -1 then
        ESX.ShowNotification('Kein Patient in der Nähe.', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetIdx)
    if not IsPedDeadOrDying(targetPed, true) then
        ESX.ShowNotification('Defibrillator nur bei bewusstlosen Patienten verwenden.', 'error')
        return
    end

    PlayCPR2Anim(Config.TreatmentTimes.defib)
    local success = lib.progressCircle({
        duration = Config.TreatmentTimes.defib,
        position = 'bottom',
        label = 'Defibrillator aufladen...',
        useWhileDead = false,
        canCancel = true
    })
    StopMedicAnim()

    if not success then return end

    -- follow-up CPR pumping to sell the shock
    PlayCPRPumpAnim(2500)
    Wait(2500)
    StopMedicAnim()

    TriggerServerEvent('clp_medic:performTreatment', 'defib', targetId, fromBag)
end)

-- Added: feedback for the medic
RegisterNetEvent('clp_medic:defibResult', function(succeeded)
    if succeeded then
        ESX.ShowNotification(Config.Defib.SuccessNotify)
        SendNUIMessage({ action = 'patientOverlay', visible = true, status = 'STABIL', heart = 'Restored' })
    else
        ESX.ShowNotification(Config.Defib.FailNotify, 'error')
        SendNUIMessage({ action = 'patientOverlay', visible = true, status = 'FLATLINE', heart = '0' })
    end
    SetTimeout(3500, function()
        SendNUIMessage({ action = 'patientOverlay', visible = false })
    end)
end)
