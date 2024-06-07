Discord = {}

local encode = json.encode
local format = string.format
local ceil = math.ceil

local VERSION<const> = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

function Discord.PostWebook(url, embed)
    PerformHttpRequest(url, function(err, text, headers)
    end, "POST", encode({
        ["username"] = "Advanced Anti VDM",
        ["embeds"] = embed
    }), {
        ["Content-Type"] = "application/json"
    })
end

local emptyBlock, filledBlock = "⬜", "🟦"
local function GetPercentageDisplay(value)
    local display = ""
    for i = 1, 10 do
        display = display .. (ceil(value) >= i * 10 and filledBlock or emptyBlock)
    end
    return display
end

local function GetIdentifierType(source, type)
    return GetPlayerIdentifierByType(source, type) or "unknownlicense"
end

function Discord.GetEmbed(source, chance, violations)
    return {
        {
            ["color"] = "3700735",
            ["author"] = {
                ["name"] = format("Advanced Anti VDM v%s", VERSION),
                ["icon_url"] = "https://raw.githubusercontent.com/EinS4ckZwiebeln/assets/main/vdm_icon.png"
            },
            ["title"] = "VDM Detected",
            ["fields"] = {
                {
                    ["name"] = "Player",
                    ["value"] = format("%s (%s)", GetPlayerName(source), source),
                    ["inline"] = true
                },
                {
                    ["name"] = "Violation(s)",
                    ["value"] = format("%sx", violations),
                    ["inline"] = true
                },
                {
                    ["name"] = "Confidence",
                    ["value"] = format("%s %s%%", GetPercentageDisplay(chance), chance),
                    ["inline"] = false
                },
                {
                    ["name"] = "License",
                    ["value"] = "```\n" .. GetIdentifierType(source, "license") .. "\n```",
                    ["inline"] = false
                },
                {
                    ["name"] = "Steam",
                    ["value"] = "```\n" .. GetIdentifierType(source, "steam") .. "\n```",
                    ["inline"] = false
                },
                {
                    ["name"] = "Discord",
                    ["value"] = "```\n" .. GetIdentifierType(source, "discord") .. "\n```",
                    ["inline"] = false
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["footer"] = {
                ["text"] = "VDM Live Alert"
            }
        }
    }
end