local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Game = require 'utils.game'

local trick = require 'map_gen.misc.trick_or_treat_chests.trick'
local treat = require 'map_gen.misc.trick_or_treat_chests.treat'

local spawn_chance = 1 / 32 --1024

local chests = {}

Global.register(
    {chests = chests},
    function(tbl)
        chests = tbl.chests
    end
)

local spawn_chest_token =
    Token.register(
    function(entity)
        chests[entity.unit_number] = true
        entity.destructible = false
        entity.minable = false
    end
)

local function shape()
    if math.random() > spawn_chance then
        return
    end

    return {name = 'steel-chest', force = 'neutral', callback = spawn_chest_token}
end

Event.add(
    defines.events.on_gui_opened,
    function(event)
        if not event.gui_type == defines.gui_type.entity then
            return
        end

        local player = Game.get_player_by_index(event.player_index)
        if not player or not player.valid then
            return
        end

        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local chest = chests[entity.unit_number]
        if not chest then
            return
        end

        if math.random() > 1 then
            trick(entity, player)
        else
            treat(entity, player)
        end

        chests[entity.unit_number] = nil
        entity.destructible = true
        entity.minable = true
    end
)

return function(chest_spawn_chance)
    spawn_chance = chest_spawn_chance or spawn_chance
    return shape
end
