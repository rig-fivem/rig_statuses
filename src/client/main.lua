--- @file src.client.main
--- @description Main client file for the statuses extension.

--- @section Imports

local _utils = require("src.client.modules.utils")
local _keys = require("src.client.modules.keys")
local _anim = require("src.client.modules.animations")

--- @section Variables

local is_downed = false
local is_dead = false

--- @section Functions

local function play_idle_crawl(ped)
    local dict = "combat@damage@writhe"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, "writhe_loop", 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function downed_crawl_loop(ped)
    local is_crawling = false
    local is_moving = false
    while is_downed do
        DisableAllControlActions(0)
        EnableControlAction(0, 32, true)
        EnableControlAction(0, 33, true)
        EnableControlAction(0, 34, true)
        EnableControlAction(0, 35, true)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 25, true)

        local forward = IsControlPressed(0, 32)
        local backward = IsControlPressed(0, 33)
        local left = IsControlPressed(0, 34)
        local right = IsControlPressed(0, 35)
        local any_movement = forward or backward or left or right

        if left then
            SetEntityHeading(ped, GetEntityHeading(ped) + 2.0)
        elseif right then
            SetEntityHeading(ped, GetEntityHeading(ped) - 2.0)
        end

        if not is_crawling then
            if forward then
                is_moving = true
                is_crawling = true
                TaskPlayAnim(ped, "move_crawl", "onfront_fwd", 8.0, -8.0, -1, 2, 0.0, false, false, false)
                SetTimeout(820, function() is_crawling = false end)
            elseif backward then
                is_moving = true
                is_crawling = true
                TaskPlayAnim(ped, "move_crawl", "onfront_bwd", 8.0, -8.0, -1, 2, 0.0, false, false, false)
                SetTimeout(990, function() is_crawling = false end)
            elseif not any_movement and is_moving then
                is_moving = false
                play_idle_crawl(ped)
            end
        end

        Wait(0)
    end
end

--- @section Events

RegisterNetEvent("rig_statuses:client:player_died", function()
    is_downed = false
    is_dead = true

    EnableAllControlActions(0)

    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    SetPedArmour(ped, 0)
    ClearPedTasks(ped)

    exports.rig_interactions:update_text_ui({
        label = "Dead",
        status_text = "You are dead...",
        action_text = "Press H to Respawn"
    })

    SetTimecycleModifier("damage")
    SetTimecycleModifierStrength(1.0)

    local dict = "dead"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    local dead_anim_letters = { "a", "b", "c", "d", "e", "f", "g", "h" }
    TaskPlayAnim(ped, dict, "dead_" .. dead_anim_letters[math.random(#dead_anim_letters)], 8.0, -8.0, -1, 1, 0, false, false, false)

    CreateThread(function()
        while is_dead do
            DisableControlAction(0, 74, true)
            if IsDisabledControlJustPressed(0, 74) then
                is_dead = false
                TriggerServerEvent("rig_statuses:server:player_respawn")
                break
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("rig_statuses:client:player_downed", function(data)
    local ped = PlayerPedId()
    is_downed = true
    is_dead = false
    local remaining = data.duration / 1000

    exports.rig_interactions:update_text_ui({
        label = "Downed",
        status_text = remaining .. "s remaining",
        action_text = "Press H to Give Up"
    })

    SetTimecycleModifier("damage")
    SetTimecycleModifierStrength(0.3)

    CreateThread(function()
        while is_downed do
            DisableControlAction(0, 74, true)
            if IsDisabledControlJustPressed(0, 74) then
                is_downed = false
                TriggerServerEvent("rig_statuses:server:player_give_up")
                break
            end
            Wait(0)
        end
    end)

    CreateThread(function()
        while is_downed and remaining > 0 do
            Wait(1000)
            remaining = remaining - 1
            if is_downed then
                exports.rig_interactions:update_text_ui({
                    label = "Downed",
                    status_text = remaining .. "s remaining",
                    action_text = "Press H to Give Up"
                })
                local strength = math.min(1.0, 0.3 + (1.0 - (remaining / (data.duration / 1000))) * 0.7)
                SetTimecycleModifierStrength(strength)
            end
        end

        if is_downed and remaining <= 0 then
            is_downed = false
            TriggerServerEvent("rig_statuses:server:player_give_up")
        end
    end)

    RequestAnimDict("combat@damage@writhe")
    while not HasAnimDictLoaded("combat@damage@writhe") do Wait(0) end
    RequestAnimDict("move_crawl")
    while not HasAnimDictLoaded("move_crawl") do Wait(0) end

    TaskPlayAnim(ped, "combat@damage@writhe", "writhe_enter", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(1500)

    if is_downed then
        TaskPlayAnim(ped, "combat@damage@writhe", "writhe_loop", 8.0, -8.0, -1, 1, 0, false, false, false)
        CreateThread(function() downed_crawl_loop(ped) end)
    end
end)

RegisterNetEvent("rig_statuses:client:respawn_player", function()
    exports.rig:trigger_callback("rig_statuses:server:validate_respawn", {}, function(response)
        if not response or not response.valid then
            log("info", "[respawn] validate failed - response: " .. tostring(response and response.valid))
            return
        end
        
        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 0)

        is_downed = false
        is_dead = false
        ClearPedTasks(PlayerPedId())
        EnableAllControlActions(0)
        ClearTimecycleModifier()
        RemoveAnimDict("move_crawl")
        RemoveAnimDict("combat@damage@writhe")

        exports.rig_interactions:destroy_text_ui()

        TriggerServerEvent("rig_spawns:server:fetch_spawns")
    end)
end)

RegisterNetEvent("rig_statuses:client:revive_player", function()

exports.rig:trigger_callback("rig_statuses:server:validate_revive", {}, function(response)
        if not response or not response.valid then
            log("info", "[revive] validate failed - response: " .. tostring(response and response.valid))
            return
        end

        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 0)

        is_downed = false
        is_dead = false
        ClearPedTasks(PlayerPedId())
        EnableAllControlActions(0)
        ClearTimecycleModifier()
        RemoveAnimDict("move_crawl")
        RemoveAnimDict("combat@damage@writhe")

        exports.rig_interactions:destroy_text_ui()
    end)
end)