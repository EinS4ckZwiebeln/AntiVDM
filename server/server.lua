local tonumber = tonumber
local abs = math.abs
local exp = math.exp
local min = math.min
local floor = math.floor

local punishment = Config.Punishment
local punish = punishment.punish
local discordWebhook = Config.DiscordWebhook
local permission = Config.Permission
local shouldReviveVictim = Config.Actions.reviveVictim

local awaitedSources = {}
local killerVictims = {}
local violations = {}

local function round(number, decimals)
    local power = 10 ^ decimals
    return floor(number * power) / power
end

RegisterServerEvent("vdm:check", function(killer)
    local src = tonumber(source)
    if src == killer then return end
    killerVictims[killer], awaitedSources[killer] = src, killer
    TriggerClientEvent("vdm:verify", killer)
end)

local SCALING_FACTOR<const> = 2.15 -- The lower the value, the more confident the script will be.
local function GetConfidenceScore(facedTargetForTime, timeToStop)
    local diff = abs(timeToStop * 1000 - facedTargetForTime)
    return min(round((exp(diff / (timeToStop * 1000 * SCALING_FACTOR)) - 1) * 100, 1), 100.0)
end

RegisterServerEvent("vdm:punish", function(facedTargetForTime, timeToStop, killerVehicleNetId)
    local src = tonumber(source)
    if not awaitedSources[src] or IsPlayerAceAllowed(src, permission) then
        return
    end
    local victim = killerVictims[src]
    violations[src] = (violations[src] or 0) + 1
    if violations[src] >= punishment.requiredViolations then
        punish(src, victim)
    end
    if discordWebhook and string.len(discordWebhook) > 0 then
        local confidence = GetConfidenceScore(facedTargetForTime, timeToStop)
        Discord.PostWebook(discordWebhook, Discord.GetEmbed(src, confidence, violations[src]))
    end
    if shouldReviveVictim then
        TriggerClientEvent("vdm:revive", victim)
    end
    if removeKillerVehicle then
        local killerVehicle = NetworkGetEntityFromNetworkId(killerVehicleNetId)
        if DoesEntityExist(killerVehicle) then DeleteEntity(killerVehicle) end
    end
    awaitedSources[src], killerVictims[src] = nil, nil
end)
