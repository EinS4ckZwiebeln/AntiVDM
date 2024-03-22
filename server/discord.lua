Discord = {}

local encode = json.encode
local format = string.format

local GetPlayerName = GetPlayerName
local PerformHttpRequest = PerformHttpRequest
local GetPlayerIdentifierByType = GetPlayerIdentifierByType

local version<const> = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

function Discord.PostWebook(url, embed)
    PerformHttpRequest(url, function(err, text, headers)
    end, "POST", encode({
        ["username"] = "Adcanced Anti VDM",
        ["embeds"] = embed
    }), {
        ["Content-Type"] = "application/json"
    })
end

local emptyBlock, filledBlock = "⬜", "🟦"
local function GetPercentageDisplay(value)
    local display = ""
    for i = 1, 10 do
        display = display .. (value >= i * 10 and filledBlock or emptyBlock)
    end
    return display
end

function Discord.GetEmbed(source, chance)
    return {
        {
            ["color"] = "3700735",
            ["author"] = {
                ["name"] = format("Advanced Anti VDM v%s", version),
                ["icon_url"] = "https://raw.githubusercontent.com/EinS4ckZwiebeln/assets/main/vdm_icon.png"
            },
            ["title"] = "VDM Detected",
            ["fields"] = {
                {
                    ["name"] = "Name",
                    ["value"] = GetPlayerName(source),
                    ["inline"] = false
                },
                {
                    ["name"] = "Confidence",
                    ["value"] = format("%s %s%%", GetPercentageDisplay(chance), chance),
                    ["inline"] = false
                },
                {
                    ["name"] = "FiveM",
                    ["value"] = GetPlayerIdentifierByType(source, "license"),
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