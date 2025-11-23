local ESX = exports['es_extended']:getSharedObject()

local function spawnVehicle(data)
    if not data or not data.model then return end

    ESX.Game.SpawnVehicle(data.model, vec3(data.spawn.x, data.spawn.y, data.spawn.z), data.spawn.w, function(vehicle)
        SetVehicleNumberPlateText(vehicle, ('MED%s'):format(math.random(100, 999)))
        SetVehicleLivery(vehicle, Config.VehicleLivery)

        if Config.EnableAllExtras then
            for extra = 0, 20 do
                if DoesExtraExist(vehicle, extra) then
                    SetVehicleExtra(vehicle, extra, 0)
                end
            end
        end

        SetVehicleEngineOn(vehicle, true, true, false)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end

local function openGarageMenu(garage)
    local options = {}
    for _, veh in ipairs(garage.vehicles) do
        options[#options+1] = {
            title = veh.label,
            description = ('Spawn %s with livery %s'):format(veh.model, Config.VehicleLivery),
            event = 'clp_medic:spawnGarageVehicle',
            args = { vehicle = veh.model, garage = garage }
        }
    end

    lib.registerContext({
        id = 'clp_medic:garage:' .. garage.label,
        title = garage.label,
        options = options
    })

    lib.showContext('clp_medic:garage:' .. garage.label)
end

RegisterNetEvent('clp_medic:spawnGarageVehicle', function(data)
    local garage = data.garage
    if not garage then return end

    spawnVehicle({
        model = data.vehicle,
        spawn = garage.spawn
    })
end)

local function registerGarages()
    for _, garage in ipairs(Config.Garages) do
        exports.ox_target:addSphereZone({
            coords = garage.coords.xyz,
            radius = garage.radius or 2.5,
            debug = Config.Debug,
            options = {
                {
                    name = ('clp_medic:garage:%s'):format(garage.label),
                    icon = 'fa-solid fa-truck-medical',
                    label = ('Garage: %s'):format(garage.label),
                    distance = 3.0,
                    canInteract = function()
                        return LocalPlayer.state.clp_medic_onDuty
                    end,
                    onSelect = function()
                        openGarageMenu(garage)
                    end
                }
            }
        })
    end
end

CreateThread(function()
    registerGarages()
end)
