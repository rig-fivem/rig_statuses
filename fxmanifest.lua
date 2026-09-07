--[[
----------------------------------------
RIG Weather (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_weather
License: https://github.com/rig-fivem/rig_weather/blob/main/LICENSE
----------------------------------------
]]

fx_version "cerulean"
games { "gta5" }
name "rig_statuses"
version "0.1.0"
description "Player statuses system for RIG (FiveM)."
license "Apache 2.0"
author "Case"
lua54 "yes"

files {
    "locales/*.json",
}

shared_script "init.lua"

client_script {
    "src/client/modules/*.lua",
    "src/client/main.lua"
}

server_scripts {
    "src/server/main.lua"
}

dependencies {
    "rig",
    "rig_interactions"
}