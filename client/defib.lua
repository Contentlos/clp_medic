-- Added: defibrillator handling
local ESX = exports['es_extended']:getSharedObject()

local function getClosestPlayer()
    local closestPlayer, distance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and distance <= Config.PatientRange then
        return GetPlayerServerId(closestPlayer)
    end
    return nil
end

RegisterNetEvent('clp_medic:useDefib', function()
    if not LocalPlayer.state.clp_medic_onDuty then
        ESX.ShowNotification('Du bist nicht im Dienst.', 'error')
        return
    end

    local targetId = getClosestPlayer()
    if not targetId then
        ESX.ShowNotification('Kein Patient in der Nähe.', 'error')
        return
    end

    local targetIdx = GetPlayerFromServerId(targetId)
    if targetIdx == -1 or not IsPedDeadOrDying(GetPlayerPed(targetIdx), true) then
        ESX.ShowNotification('Defibrillator nur bei bewusstlosen Patienten verwenden.', 'error')
        return
    end

    local animDict = 'mini@cpr@char_a@cpr_str'
    local anim = 'cpr_pumpchest'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    local success = lib.progressCircle({
        duration = Config.TreatmentTimes.defib,
        position = 'bottom',
        label = 'Defibrillator aufladen...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = animDict,
            clip = anim
        }
    })

    ClearPedTasks(PlayerPedId())
    if not success then return end

    TriggerServerEvent('clp_medic:performDefib', targetId)
end)

-- Added: feedback for the medic
RegisterNetEvent('clp_medic:defibResult', function(succeeded)
    if succeeded then
        ESX.ShowNotification(Config.Defib.SuccessNotify)
    else
        ESX.ShowNotification(Config.Defib.FailNotify, 'error')
    end
end)
