Config = {}

-- Enable debug mode.
Config.Debug = false

-- Permission required to bypass the scripts detection.
Config.Permission = "vdm.bypass"

-- Discord webhook URL.
Config.DiscordWebhook = ""

-- Wether or not the script should be aggressive about detecting VDM.
-- Strict mode may result in more false positives.
Config.Mode = "MODERATE" -- Available modes: RELAXED, MODERATE, STRICT

-- Increase this value if players on your server come together in very large groups.
-- However, the default value should be fine for most servers.
Config.MaxTargets = 10

-- You might want to add emergency vehicles to this list (18).
-- https://docs.fivem.net/natives/?_0x29439776AAA00A62
Config.IgnoredVehicleClasses = { 14, 15, 16, 21 }

Config.Punishment = {
    -- The amount of violations required to trigger punishment.
    requiredViolations = 1,
    -- The punishment to be executed.
    punish = function(suspect, victim)
        -- You can add your own punishment logic here:
        print(("^1Player %s has been flagged for VDM^0"):format(GetPlayerName(suspect)))
    end
}

Config.Actions = {
    -- Enable this if you want to auto-revive victims of VDM.
    reviveVictim = true,
    -- Enable this if you want to restore the victims health after being revived.
    restoreVictimHealth = true,
    -- Enable this if you want to delete the killers vehicle after the VDM incident.
    removeKillerVehicle = false
}
