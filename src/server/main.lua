--- @file src/server/main.lua
--- @description Main server side handling

--- @section RIG Events

AddEventHandler("rig:server:player_died", function(source)
    TriggerClientEvent("rig_statuses:client:player_died", source)
end)

AddEventHandler("rig:server:player_downed", function(source, data)
    TriggerClientEvent("rig_statuses:client:player_downed", source, data)
end)

AddEventHandler("rig:server:player_picked_up", function(source)
    TriggerClientEvent("rig_statuses:client:player_picked_up", source)
end)

AddEventHandler("rig:server:player_revived", function(source)
    TriggerClientEvent("rig_statuses:client:revive_player", source)
end)

AddEventHandler("rig:server:player_respawn_started", function(source)
    TriggerClientEvent("rig_statuses:client:respawn_player", source)
end)

--- @section Events

RegisterServerEvent("rig_statuses:server:player_respawn", function()
    local _src = source

    local is_dead = exports.rig:is_player_dead(_src)
    if not is_dead then
        log("info", "player isnt dead")
        return
    end

    exports.rig:begin_player_respawn(_src)
end)

RegisterServerEvent("rig_statuses:server:player_give_up", function()
    local _src = source

    local is_downed = exports.rig:is_player_downed(_src)
    if not is_downed then
        log("info", "player isnt downed")
        return
    end

    exports.rig:kill_player(_src)
end)

--- @section Callbacks

exports.rig:register_callback("rig_statuses:server:validate_revive", function(source, data, cb)
    local is_pending = exports.rig:get_player_status(source, "pending_revive") == true
    if is_pending then
        exports.rig:set_player_status(source, "pending_revive", false)
    end

    cb({ valid = is_pending })
end)

exports.rig:register_callback("rig_statuses:server:validate_respawn", function(source, data, cb)
    local is_dead = exports.rig:is_player_dead(source) == true
    cb({ valid = is_dead })
end)