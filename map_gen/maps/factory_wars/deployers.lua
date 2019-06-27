local Event = require 'utils.event'
local Global = require 'utils.global'
local table = require 'utils.table'

local fast_remove = table.fast_remove
local floor = math.floor
local raise_event = script.raise_event
local on_entity_spawned = defines.events.on_entity_spawned

local deployer_names = {
    ['basic-unit-deployer'] = true,
    ['advanced-unit-deployer'] = true,
    ['superior-unit-deployer'] = true,
    ['experimental-unit-deployer'] = true
}

local direction_offests = {
    [defines.direction.north] = {0, 1},
    [defines.direction.east] = {-1, 0},
    [defines.direction.south] = {0, -1},
    [defines.direction.west] = {1, 0}
}

local machine_output = defines.inventory.assembling_machine_output

local max_partition = 8
local deployers = {partition = max_partition}

Global.register(
    deployers,
    function(tbl)
        deployers = tbl
    end
)

local function entity_built(event)
    local entity = event.created_entity
    if not entity or not entity.valid or not deployer_names[entity.name] then
        return
    end

    deployers[#deployers + 1] = entity
end

local function get_output_position(area, position, direction)
    local top = area.left_top
    local x, y = top.x, top.y
    local posx, posy = position.x, position.y

    local offset = direction_offests[direction]
    local ox, oy = offset[1], offset[2]

    return {posx + ox * x, posy + oy * y}
end

local function tick()
    local count = #deployers
    local old_partition = deployers.partition

    local start_index
    local end_index

    local partition
    if old_partition == max_partition then
        start_index = 1
        partition = 1
    else
        partition = old_partition + 1
        start_index = floor(count / old_partition) + 1
    end

    if partition == max_partition then
        end_index = count
    else
        end_index = floor(count / partition)
    end

    deployers.partition = partition

    for i = end_index, start_index, -1 do
        local entity = deployers[i]
        if not entity.valid then
            fast_remove(deployers, i)
        else
            local inventory = entity.get_inventory(machine_output)

            local inv_count = #inventory
            if inv_count == 0 then
                goto continue
            end

            local stack = inventory[1]
            if not stack or not stack.valid or not stack.valid_for_read then
                goto continue
            end

            local name = stack.name
            local box = entity.bounding_box
            local direction = entity.direction
            local position = entity.position

            local target_output_pos = get_output_position(box, position, direction)

            local surface = entity.surface

            local output_position = surface.find_non_colliding_position(name, target_output_pos, 16, 1)
            if output_position then
                local unit = surface.create_entity {name = name, position = output_position, force = entity.force}
                raise_event(on_entity_spawned, {entity = unit, spawner = entity})
                inventory.remove({name = name, count = 1})
            end
        end

        ::continue::
    end
end

Event.add(defines.events.on_built_entity, entity_built)
Event.add(defines.events.on_robot_built_entity, entity_built)
Event.on_nth_tick(2, tick)
