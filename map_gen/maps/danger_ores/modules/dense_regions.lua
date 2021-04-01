local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise

return function(config)
    local sources = {
        {seed = seed_provider(), scale = 1/50, multiplier = 1},
        {seed = seed_provider(), scale = 1/8, multiplier = 0.1},
        {seed = seed_provider(), scale = 1/2, multiplier = 0.05},
    }

    local threshold = config.dense_regions_threshold or 0.4
    local richness_power = config.dense_regions_richness_power or 4.5

    local inv_threshold = 1 / threshold

    return function(x, y, entity)
        local total = 0
        for _, source in pairs(sources) do
            local scale = source.scale
            local value = perlin_noise(scale * x, scale * y, source.seed)
            local normalised_value = (value + 1) / 2
            total = total + normalised_value * source.multiplier
        end

        if total > threshold then
            local multiplier = math.max(1, 0.5 * (total * inv_threshold) ^ richness_power)
            entity.amount = entity.amount * multiplier
        end
    end
end

--[[ return function(config)
    local scale = config.dense_patches_scale or (1 / 48)
    local threshold = config.dense_patches_threshold or 0.5
    local multiplier = config.dense_patches_multiplier or 50
    local seed = config.dense_patches_seed or seed_provider()

    return function(x, y, entity)
        x, y = x * scale, y * scale
        local noise = perlin_noise(x, y, seed)
        if noise > threshold then
            entity.amount = entity.amount * multiplier
        end
    end
end ]]