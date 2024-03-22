fx_version "cerulean"
game "gta5"

author "EinS4ckZwiebeln"
description "Advanced VDM Detection"
version "1.0.0"

lua54 "yes"

shared_script "config.lua"

client_script {
    "client/*.lua"
}

server_script {
    "server/discord.lua",
    "server/server.lua"
}

dependencies {
    "/onesync", 
    "/server:5181", 
    "baseevents"
}
