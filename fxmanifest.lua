fx_version "cerulean"
game "gta5"

author "EinS4ckZwiebeln"
description "Advanced VDM Detection"
version "1.0.0"

lua54 "yes"
use_experimental_fxv2_oal "yes"

shared_script "config.lua"

client_script {
    "client/*.lua"
}

server_script {
    "server/discord.lua",
    "server/server.lua"
}

dependencies {
    "/server:7290",
    "/onesync"
}
