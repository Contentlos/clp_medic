-- NEW: hospital bed placements, locker access, and small RP actions
local ESX = exports['es_extended']:getSharedObject()

local function canUse()
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

-- Hospital beds
for index, bed in ipairs(Config.HospitalBeds) do
    exports.ox_target:addBoxZone({
        coords = vec3(bed.coords.x, bed.coords.y, bed.coords.z),
        size = vec3(1.6, 2.0, 1.0),
        rotation = bed.coords.w,
        debug = Config.Debug,
        options = {
            {
                name = ('clp_medic:bed:%s'):format(index),
                icon = 'fa-solid fa-bed',
                label = ('%s - Patienten ablegen'):format(bed.label),
                canInteract = function()
                    return LocalPlayer.state.clp_medic_onDuty == true and canUse()
                end,
                onSelect = function()
                    local closestPlayer, dist = ESX.Game.GetClosestPlayer()
                    if closestPlayer ~= -1 and dist <= Config.PatientRange then
                        TriggerServerEvent('clp_medic:bed:place', GetPlayerServerId(closestPlayer), index)
                    else
                        ESX.ShowNotification('Kein Patient in Reichweite.', 'error')
                    end
                end
            }
        }
    })
end

RegisterNetEvent('clp_medic:bed:set', function(coords, autoHeal, bedIndex)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, true)
    PlayPlaceAnim(2500)
    if autoHeal and autoHeal.enabled then
        CreateThread(function()
            while FreezeEntityPosition(ped) do
                Wait(autoHeal.interval or 4000)
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, math.min(200, health + (autoHeal.amount or 5)))
                if health >= 200 then break end
            end
        end)
    end
    CreateThread(function()
        while FreezeEntityPosition(ped) do
            Wait(0)
            if IsControlJustReleased(0, 22) or GetEntityHealth(ped) >= 200 then
                FreezeEntityPosition(ped, false)
                TriggerServerEvent('clp_medic:bed:release', bedIndex)
                break
            end
        end
    end)
end)

-- Lockers
for _, locker in ipairs(Config.Lockers) do
    exports.ox_target:addSphereZone({
        coords = locker.coords,
        radius = locker.radius or 1.5,
        debug = Config.Debug,
        options = {
            {
                icon = 'fa-solid fa-briefcase-medical',
                label = locker.label or 'EMS Spind',
                canInteract = function()
                    return LocalPlayer.state.clp_medic_onDuty == true and canUse()
                end,
                onSelect = function()
                    TriggerServerEvent('clp_medic:locker:request', index)
                end
            }
        }
    })
end

-- Flavor RP actions
exports.ox_target:addGlobalPlayer({
    {
        name = 'clp_medic:flavor:pulse',
        icon = 'fa-solid fa-hand-holding-heart',
        label = 'Schnellcheck',
        canInteract = function()
            return LocalPlayer.state.clp_medic_onDuty == true and canUse()
        end,
        onSelect = function(data)
            local ped = PlayerPedId()
            PlayFlavorAnim(4000)
            lib.progressCircle({
                duration = 4000,
                label = 'Check läuft...',
                position = 'bottom'
            })
            StopMedicAnim()
            local idx = math.random(1, #Config.FlavorChecks)
            local result = Config.FlavorChecks[idx]
            if result then
                ESX.ShowNotification(result.text)
                Wait(500)
                ESX.ShowNotification(result.result)
            end
        end
    }
})

-- Billing target (optional)
exports.ox_target:addGlobalPlayer({
    {
        name = 'clp_medic:bill',
        icon = 'fa-solid fa-file-invoice-dollar',
        label = 'Behandlungsrechnung',
        canInteract = function()
            return Config.Billing.Enabled and LocalPlayer.state.clp_medic_onDuty == true and canUse()
        end,
        onSelect = function(data)
            TriggerServerEvent('clp_medic:billPatient', GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
        end
    }
})
