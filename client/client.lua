local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local GetEntityForwardVector = GetEntityForwardVector
local IsPedOnFoot = IsPedOnFoot
local IsPedDeadOrDying = IsPedDeadOrDying
local GetEntitySpeed = GetEntitySpeed
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetGamePool = GetGamePool
local PlayerPedId = PlayerPedId
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsVehicleOnAllWheels = IsVehicleOnAllWheels
local GetVehicleHandlingFloat = GetVehicleHandlingFloat
local GetEntityModel = GetEntityModel
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetPlayerServerId = GetPlayerServerId
local IsPedAPlayer = IsPedAPlayer
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local DrawLine = DrawLine
local DoesEntityExist = DoesEntityExist
local GetActivePlayers = GetActivePlayers
local TriggerServerEvent = TriggerServerEvent
local GetHashKey = GetHashKey
local GetPlayerPed = GetPlayerPed
local NetworkResurrectLocalPlayer = NetworkResurrectLocalPlayer
local SetPlayerInvincible = SetPlayerInvincible
local PlayerId = PlayerId
local GetVehicleClass = GetVehicleClass
local IsVehicleDriveable = IsVehicleDriveable
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local GetEntitySpeedVector = GetEntitySpeedVector
local SetEntityHealth = SetEntityHealth
local GetEntityMaxHealth = GetEntityMaxHealth
local DeleteEntity = DeleteEntity
local SetEntityAsNoLongerNeeded = SetEntityAsNoLongerNeeded

local sqrt = math.sqrt
local acos = math.acos
local cos = math.cos
local sin = math.sin
local abs = math.abs
local deg = math.deg
local rad = math.rad
local floor = math.floor

local sort = table.sort
local format = string.format
local joaat = joaat

local vec3 = vec3
local vec2 = vec2

local debug = Config.Debug
local mode = Config.Mode
local maxTargets = Config.MaxTargets
local shouldReviveVictim = Config.Actions.reviveVictim
local ignoredVehicleClasses = Config.IgnoredVehicleClasses
local restoreVictimHealth = Config.Actions.restoreVictimHealth
local removeKillerVehicle = Config.Actions.removeKillerVehicle

local closestPlayers = {}
local facedTargetForTime = 0
local maxSpeed = 0
local globalAngle = 0

local settings = {
    ["RELAXED"] = {
        maxAngle = 8.0,
        stopOffset = 0.15
    },
    ["MODERATE"] = {
        maxAngle = 14.0,
        stopOffset = 0.0
    },
    ["STRICT"] = {
        maxAngle = 20.0,
        stopOffset = -0.15
    }
}

if settings[mode] == nil then
    print("^1VDM: Invalid mode, defaulting to MODERATE")
    mode = "MODERATE"
end

local maxAngle = settings[mode].maxAngle
local stopOffset = settings[mode].stopOffset

local ignoredClasses = {}
for i = 1, #ignoredVehicleClasses do
    ignoredClasses[ignoredVehicleClasses[i]] = true
end

local function round(number, decimals)
    local power = 10 ^ decimals
    return floor(number * power) / power
end

local function GetTimeToStop(vehicle)
    local clearedSpeed = maxSpeed + abs(maxSpeed - GetEntitySpeed(vehicle))
    return (clearedSpeed / (GetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce") * 10)) / 2
end

local function IsFacingPed(vehicle, target, inReverse)
    local vCoords, tCoords = GetEntityCoords(vehicle), GetEntityCoords(target)
    -- Calculate the direction the vehicle is facing while taking reverse driving into account
    local forwardVector = inReverse and -GetEntityForwardVector(vehicle) or GetEntityForwardVector(vehicle)
    local forwardX, forwardY = forwardVector.x, forwardVector.y

    -- Calculate the vector from the vehicle to the target
    local toTargetVector = vec2(tCoords.x - vCoords.x, tCoords.y - vCoords.y)
    local targetX, targetY = toTargetVector.x, toTargetVector.y

    -- Normalize the vectors (make them unit vectors)
    local forwardVectorLength = sqrt(forwardX * forwardX + forwardY * forwardY)
    local toTargetVectorLength = sqrt(targetX * targetX + targetY * targetY)

    local forwardVectorNormalized = vec2(forwardX / forwardVectorLength, forwardY / forwardVectorLength)
    local toTargetVectorNormalized = vec2(targetX / toTargetVectorLength, targetY / toTargetVectorLength)

    -- Calculate the dot product between the two normalized vectors
    local dotProduct = forwardVectorNormalized.x * toTargetVectorNormalized.x + forwardVectorNormalized.y *
                           toTargetVectorNormalized.y

    -- Calculate the angle between the vectors using the dot product
    local angle = deg(acos(dotProduct))
    -- Set a fixed tolerance angle (adjust as needed)
    if debug then
        globalAngle = angle
    end
    return angle <= maxAngle
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) and GetEntityHeightAboveGround(ped) < 8.0 then
            local vehicle = GetVehiclePedIsIn(ped, false)
            -- Only check for VDM if the vehicle is a car, bike or truck and driveable
            if IsVehicleDriveable(vehicle, true) and not ignoredClasses[GetVehicleClass(vehicle)] then

                local coords = GetEntityCoords(ped)
                local pool = GetActivePlayers()

                local function SortByDistance(a, b)
                    return #(coords - GetEntityCoords(a)) < #(coords - GetEntityCoords(b))
                end
                sort(pool, SortByDistance)

                closestPlayers = {}
                local pLength = #pool
                local availableTargets = pLength < maxTargets and pLength or maxTargets
                for i = 1, availableTargets do
                    local target = GetPlayerPed(pool[i])
                    if DoesEntityExist(target) and IsPedOnFoot(target) and not IsPedDeadOrDying(target) then
                        closestPlayers[#closestPlayers + 1] = target
                    end
                end

                local length = #closestPlayers
                local wasFacingPlayer = false
                local inReverse = GetEntitySpeedVector(vehicle, true).y < 0.0

                for i = 1, length do
                    local player = closestPlayers[i]
                    while IsFacingPed(vehicle, player, inReverse) do
                        Citizen.Wait(50)
                        local speed = GetEntitySpeed(vehicle)
                        facedTargetForTime = facedTargetForTime + 50
                        if speed > maxSpeed then
                            maxSpeed = speed
                        end
                        wasFacingPlayer = true
                        if speed < 3 * 3.6 then
                            break
                        end
                    end

                    if wasFacingPlayer and (facedTargetForTime / 1000) > 1.0 then
                        Citizen.Wait(1000)
                        wasFacingPlayer = false
                    end
                    facedTargetForTime, maxSpeed = 0, 0
                end
            end
        end
    end
end)

RegisterNetEvent("vdm:revive", function()
    local ped = PlayerPedId()
    if shouldReviveVictim and IsPedDeadOrDying(ped) then
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityRotation(ped), true, false)
        SetPlayerInvincible(ped, false)
        if restoreVictimHealth then
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
        end
        if debug then
            print("^1VDM: Revived victim")
        end
    end
end)

RegisterNetEvent("vdm:verify", function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local timeToStop = GetTimeToStop(vehicle)
        if (facedTargetForTime / 1000) > (timeToStop + stopOffset) then
            TriggerServerEvent("vdm:punish", facedTargetForTime, timeToStop + stopOffset)

            if removeKillerVehicle then
                SetEntityAsNoLongerNeeded(vehicle)
                DeleteEntity(vehicle)
            end
        end
        if debug then
            print("^1VDM: Time to stop: " .. round(timeToStop, 2) .. "s",
                "^1VDM: Faced target for: " .. facedTargetForTime / 1000 .. "s")
        end
    end
end)

AddEventHandler("baseevents:onPlayerKilled", function(killerId, deathData)
    if killerId == -1 and deathData.killervehseat == -1 and deathData.weaponhash == -1553120962 and
        deathData.killerinveh then
        local coords = GetEntityCoords(PlayerPedId())
        local vehicles = GetGamePool("CVehicle")

        local function SortByDistance(a, b)
            return #(coords - GetEntityCoords(a)) < #(coords - GetEntityCoords(b))
        end
        sort(vehicles, SortByDistance)

        local killerVehicle = nil
        local modelHash = joaat(deathData.killervehname)
        local length = #vehicles

        for i = 1, length do
            local vehicle = vehicles[i]
            if GetEntityModel(vehicle) == modelHash then
                killerVehicle = vehicle
                break
            end
        end
        -- Fallback to closest vehicle
        if not killerVehicle and length > 0 then
            killerVehicle = vehicles[1]
        end
        if killerVehicle then
            local killerPed = GetPedInVehicleSeat(killerVehicle, -1)
            if IsPedAPlayer(killerPed) then
                local killerSource = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerPed))
                TriggerServerEvent("vdm:check", killerSource)
                if debug then
                    print("^1VDM: Checking " .. killerSource)
                end
            end
        elseif debug then
            print("^1VDM: Could not find killer vehicle")
        end
    end
end)

-- Debug 
Citizen.CreateThread(function()
    local SetTextFont = SetTextFont
    local SetTextProportional = SetTextProportional
    local SetTextScale = SetTextScale
    local SetTextColour = SetTextColour
    local SetTextDropshadow = SetTextDropshadow
    local SetTextEdge = SetTextEdge
    local SetTextDropShadow = SetTextDropShadow
    local SetTextOutline = SetTextOutline
    local SetTextEntry = SetTextEntry
    local AddTextComponentString = AddTextComponentString
    local DrawText = DrawText

    while debug do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local timeToStop = GetTimeToStop(vehicle)

            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.4)
            SetTextColour(128, 128, 128, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(format("Mode: %s\nT-Face: %s%ss~c~\nT-Stop: %ss\nCl-Peds: %s\nAngle: %s", mode,
                facedTargetForTime / 1000 > timeToStop and "~r~" or "", round(facedTargetForTime / 1000, 2),
                round(timeToStop, 2), #closestPlayers, round(globalAngle, 2)))
            DrawText(0.005, 0.005)
        end
    end
end)

