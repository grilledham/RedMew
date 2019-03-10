local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'

local Public = {}

local memory = {
    launched = nil,
    rocket_silo = nil
}

Global.register(
    memory,
    function(tbl)
        memory = tbl
    end
)

local nest_names = {
    'biter-spawner',
    'spitter-spawner',
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret',
    'behemoth-worm-turret'
}

local collect_nests =
    Token.register(
    function(data)
        local x, y = data.x, data.y
        local area = {top_left = {x, y}, bottom_right = {x + 32, y + 32}}
        local entities = data.surface.find_entities_filtered {area = area, name = nest_names}
        local nests = data.nests
        local nests_set = data.nests_set

        for i = 1, #entities do
            local entity = entities[i]
            local unit_number = entity.unit_number

            if not nests_set[unit_number] then
                nests[#nests + 1] = entity
                nests_set[unit_number] = true
            end
        end

        game.print('nests count: ' .. #nests)

        x = x + 32

        if x > data.bottom_right_x then
            data.x = data.top_left_x
            y = y + 32
            data.y = y
        else
            data.x = x
        end

        if y > data.bottom_right_y then
            game.print('done, nests count: ' .. #nests)
            return false
        end

        return true
    end
)

function do_end(area, surface)
    area = area or memory.area
    local tl, br = area.top_left, area.bottom_right
    local data = {
        top_left_x = tl.x,
        top_left_y = tl.y,
        bottom_right_x = br.x,
        bottom_right_y = br.y,
        x = tl.x,
        y = tl.y,
        surface = surface,
        nests = {},
        nests_set = {}
    }
    Task.queue_task(collect_nests, data, 2700)
end

function Public.register(area)
    memory.area = area
    Event.add(
        defines.events.on_rocket_launch_ordered,
        function(event)
            local entity = event.rocket
            if not entity or not entity.valid then
                return
            end

            local inventory = entity.get_inventory(defines.inventory.rocket)
            if not inventory or not inventory.valid then
                return
            end

            local count = inventory.get_item_count('satellite')
            if count == 0 then
                return
            end

            memory.rocket_silo = event.entity
            memory.launched = true

            do_end(area, entity.surface)
        end
    )
end

return Public
