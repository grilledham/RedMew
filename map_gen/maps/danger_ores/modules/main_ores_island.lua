local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'
local random = math.random

local function no_op()
end

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0
    local resource_patches = (config.resource_patches or no_op)(config) or b.empty_shape
    local dense_patches = (config.dense_patches or no_op)(config) or no_op

    local start_ore_shape = config.start_ore_shape or b.circle(68)

    local function apply_resource_patches(x,y, world, entity)
        local resource_patches_entity = resource_patches(x, y, world)
        if resource_patches_entity ~= false then
            return resource_patches_entity
        end

        dense_patches(x, y, entity)
        entity.enable_tree_removal = false

        return entity
    end

    local function island_factory()
        local resources = {
            {name = 'iron-ore', seed = seed_provider(), scale = 1/64, weight = 45},
            {name = 'copper-ore', seed = seed_provider(), scale = 1/64, weight = 35},
            {name = 'coal', seed = seed_provider(), scale = 1/32, weight = 15},
            {name = 'stone', seed = seed_provider(), scale = 1/32, weight = 5},
        }

        local threshold = 0.58

        return function(x, y, world)
            local values = {}
            for i = 1, #resources do
                local resource = resources[i]
                local scale = resource.scale
                local value = Perlin.noise(scale * x, scale * y, resource.seed)
                local normalised_value = (value + 1) * 0.5

                if normalised_value < threshold then
                    normalised_value = 0
                end

                values[#values+1] = resource.weight * normalised_value
            end

            local total = table.sum(values)

            if total < threshold then
                return nil
            end

            local rand = random() * total

            local d = (world.x ^ 2 + world.y ^ 2) ^ 0.5

            for i = 1, #values do
                local v = values[i]
                if rand < v then
                    local resource = resources[i]
                    local nosie_factor = ((v / threshold / resource.weight) ^ 4) * 0.33
                    local amount = 0.75 * nosie_factor * d
                    return {name = resource.name, amount = math.max(1, amount)}
                end

                rand = rand - v
            end

            return nil
        end
    end

    local function dense_factory()
        local sources = {
            {seed = seed_provider(), scale = 1/50, multiplier = 1},
            {seed = seed_provider(), scale = 1/8, multiplier = 0.1},
            {seed = seed_provider(), scale = 1/2, multiplier = 0.05},
        }

        local threshold = 0.4
        local richness_power = 3

        local inv_threshold = 1 / threshold

        return function(x, y, world)
            local total = 0
            for _, source in pairs(sources) do
                local scale = source.scale
                local value = Perlin.noise(scale * x, scale * y, source.seed)
                local normalised_value = (value + 1) / 2
                total = total + normalised_value * source.multiplier
            end

            if total > threshold then
                local amount = math.max(1, 100 * (total * inv_threshold) ^ richness_power)
                return {name = 'iron-ore', amount = amount}
            end

            return nil
        end
    end

    return function(tile_builder, _, spawn_shape, water_shape, random_gen)
        local pattern = {}
        for ore_name, data in pairs(main_ores) do
            pattern[#pattern + 1] = {ore_name = ore_name, data = data}
        end

        if shuffle_order then
            table.shuffle_table(pattern, random_gen)
        end

        local start_ore_shapes = {}
        local ore_pattern = {}
        for _, value in pairs(pattern) do
            local ore_name = value.ore_name
            local data = value.data
            start_ore_shapes[#start_ore_shapes + 1] = b.resource(b.full_shape, ore_name, data.start)
            ore_pattern[#ore_pattern + 1] = data
        end

        local land = tile_builder({'grass-1', 'grass-2', 'grass-3', 'grass-4'})        

        local start_ores = b.segment_pattern(start_ore_shapes)
        start_ores = b.rotate(start_ores, math.rad(45))
        local main_ores_shape = dense_factory()
        main_ores_shape = b.apply_effect(main_ores_shape, apply_resource_patches)
        local ores = b.choose(start_ore_shape, start_ores, main_ores_shape)

        local map = b.apply_entity(land, ores)

        if main_ores_rotate ~= 0 then
            map = b.rotate(map, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, map}
    end
end
