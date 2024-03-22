local TriggerClientEvent = TriggerClientEvent
local TriggerEvent = TriggerEvent
local DropPlayer = DropPlayer
local IsPlayerAceAllowed = IsPlayerAceAllowed

local encode = json.encode
local tonumber = tonumber
local abs = math.abs
local len = string.len

local debug = Config.Debug
local punishment = Config.Punishment
local punish = punishment.punish
local discordWebhook = Config.DiscordWebhook
local permission = Config.Permission
local shouldReviveVictim = Config.Actions.reviveVictim

local PostWebhook = Discord.PostWebook
local GetEmbed = Discord.GetEmbed

local awaitedSources = {}
local killerVictims = {}
local violations = {}

RegisterServerEvent("vdm:check", function(killer)
    local src = tonumber(source)
    if src == killer then
        return
    end
    killerVictims[killer] = src
    awaitedSources[killer] = killer
    TriggerClientEvent("vdm:verify", killer)
end)

RegisterServerEvent("vdm:punish", function(facedTargetForTime, timeToStop)
    local src = tonumber(source)
    if not awaitedSources[src] then
        return
    end
    if IsPlayerAceAllowed(src, permission) then
        return
    end
    -- Calculate confidence score
    local confidence = 0.0
    local diff = abs(timeToStop * 1000, facedTargetForTime)
    for i = 1, diff, 100 do
        local increment = confidence + 2.5
        if (increment > 100) then
            break
        end
        confidence = increment
    end

    if len(discordWebhook) > 0 then
        PostWebhook(discordWebhook, GetEmbed(src, confidence))
    end
    local victim = killerVictims[src]
    -- Increment violation counter
    violations[src] = (violations[src] or 0) + 1
    if violations[src] >= punishment.requiredViolations then
        punish(src, victim)
    end
    if shouldReviveVictim then
        TriggerClientEvent("vdm:revive", victim)
    end

    awaitedSources[src] = nil
    killerVictims[src] = nil
end)
