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
local removeKillerVehicle = Config.Actions.removeKillerVehicle

local killerVictims = {}
local violations = {}

local function round(number, decimals)
    local power = 10 ^ decimals
    return floor(number * power) / power
end

RegisterServerEvent("vdm:check", function(killer)
    local victim = tonumber(source)
    if victim == killer then return end
    killerVictims[killer] = victim
    TriggerClientEvent("vdm:verify", killer)
end)

local SCALING_FACTOR<const> = 2.15 -- The lower the value, the more confident the script will be.
local function GetConfidenceScore(facedTargetForTime, timeToStop)
    local diff = abs(timeToStop * 1000 - facedTargetForTime)
    return min(round((exp(diff / (timeToStop * 1000 * SCALING_FACTOR)) - 1) * 100, 1), 100.0)
end

RegisterServerEvent("vdm:punish", function(facedTargetForTime, timeToStop, killerVehicleNetId)
    local killer = tonumber(source)
    local victim = killerVictims[killer]
    if not victim or IsPlayerAceAllowed(killer, permission) then
        return
    end
    violations[killer] = (violations[killer] or 0) + 1
    if violations[killer] >= punishment.requiredViolations then
        punish(killer, victim)
    end
    if discordWebhook and string.len(discordWebhook) > 0 then
        local confidence = GetConfidenceScore(facedTargetForTime, timeToStop)
        Discord.PostWebook(discordWebhook, Discord.GetEmbed(killer, confidence, violations[killer]))
    end
    if shouldReviveVictim then
        TriggerClientEvent("vdm:revive", victim)
    end
    if removeKillerVehicle then
        local killerVehicle = NetworkGetEntityFromNetworkId(killerVehicleNetId)
        if DoesEntityExist(killerVehicle) then DeleteEntity(killerVehicle) end
    end
    killerVictims[killer] = nil
end)
