local b = require 'map_gen.shared.builders'
local Token = require 'utils.global_token'
local Task = require 'utils.Task'

local kill_token =
    Token.register(
    function(player)
        local c = player.character

        if not c then
            return
        end

        local e = c.surface.create_entity {name = 'fish', position = c.position}
        c.die(nil, e)
    end
)

local damage_token =
    Token.register(
    function(player)
        local c = player.character

        if not c then
            return
        end

        local e = c.surface.create_entity {name = 'fish', position = c.position}
        c.damage(150, 'enemy')
    end
)

local function damage(entity, player)
    local c = player.character

    if not c then
        return
    end

    player.print('An evil fish has bitten you.')

    if c.health <= 150 then
        -- For some reason the kill has to be delayed by one tick else the game crashes to desktop.
        Task.set_timeout_in_ticks(1, kill_token, player)
    else
        Task.set_timeout_in_ticks(1, damage_token, player)
    end
end

local biters = {
    'small-biter',
    'medium-biter',
    'big-biter',
    'behemoth-biter'
}

local spitters = {
    'small-spitter',
    'medium-spitter',
    'big-spitter',
    'behemoth-spitter'
}

local worms = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local function spawn_biter(entity, player)
    local p = entity.position
    local d = math.sqrt(p.x * p.x + p.y * p.y)

    local count = math.random(2, 6)
    local index = math.floor(d / 256) + 1
    index = math.clamp(index, 1, 4)
    local name = biters[index]

    local surface = entity.surface

    for _ = 1, count do
        local p2 = surface.find_non_colliding_position(name, p, 32, 1)
        surface.create_entity {name = name, position = p2}
    end

    player.print('A pack of wild biters appeared.')
end

local function spawn_spitters(entity, player)
    local p = entity.position
    local d = math.sqrt(p.x * p.x + p.y * p.y)

    local count = math.random(2, 6)
    local index = math.floor(d / 256) + 1
    index = math.clamp(index, 1, 4)
    local name = spitters[index]

    local surface = entity.surface

    for _ = 1, count do
        local p2 = surface.find_non_colliding_position(name, p, 32, 1)
        surface.create_entity {name = name, position = p2}
    end

    player.print('A pack of wild spitters appeared.')
end

local function spawn_worms(entity, player)
    local p = entity.position
    local d = math.sqrt(p.x * p.x + p.y * p.y)

    local count = math.random(2, 4)
    local index = math.floor(d / 384) + 1
    index = math.clamp(index, 1, 3)
    local name = worms[index]

    local surface = entity.surface

    for _ = 1, count do
        local p2 = surface.find_non_colliding_position(name, p, 32, 1)
        surface.create_entity {name = name, position = p2}
    end

    player.print('A pack of wild worms appeared.')
end

local function spill_inventory(inventory, surface, position)
    for k, v in pairs(inventory.get_contents()) do
        local stack = {name = k, count = v}
        surface.spill_item_stack(position, stack)
        inventory.remove(stack)
    end
end

local function spill(entity, player)
    local surface = player.surface
    local pos = player.position

    spill_inventory(player.get_main_inventory(), surface, pos)
    spill_inventory(player.get_quickbar(), surface, pos)
    spill_inventory(player.get_inventory(defines.inventory.player_guns), surface, pos)
    spill_inventory(player.get_inventory(defines.inventory.player_ammo), surface, pos)
    spill_inventory(player.get_inventory(defines.inventory.player_armor), surface, pos)
    spill_inventory(player.get_inventory(defines.inventory.player_tools), surface, pos)

    player.print('Butterfingers.')
end

local tricks = {
    {func = damage, weight = 1},
    {func = spawn_biter, weight = 1},
    {func = spawn_spitters, weight = 1},
    {func = spawn_worms, weight = 1},
    {func = spill, weight = 1}
}

local weighted = b.prepare_weighted_array(tricks)

return function(entity, player)
    local i = math.random() * weighted.total
    local item = b.get_weighted_item(tricks, weighted, i)

    item.func(entity, player)
end
