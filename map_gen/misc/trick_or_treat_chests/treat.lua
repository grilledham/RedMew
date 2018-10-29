local b = require 'map_gen.shared.builders'

local item_pool = {
    {name = 'firearm-magazine', count = 200, weight = 1250},
    {name = 'land-mine', count = 100, weight = 250},
    {name = 'shotgun-shell', count = 200, weight = 1250},
    {name = 'piercing-rounds-magazine', count = 200, weight = 833.3333},
    {name = 'science-pack-1', count = 200, weight = 100},
    {name = 'science-pack-2', count = 200, weight = 100},
    {name = 'grenade', count = 100, weight = 500},
    {name = 'defender-capsule', count = 50, weight = 500},
    {name = 'railgun-dart', count = 100, weight = 500},
    {name = 'piercing-shotgun-shell', count = 200, weight = 312.5},
    {name = 'steel-axe', count = 5, weight = 166.6667},
    {name = 'submachine-gun', count = 1, weight = 166.6667},
    {name = 'shotgun', count = 1, weight = 166.6667},
    {name = 'uranium-rounds-magazine', count = 200, weight = 166.6667},
    {name = 'cannon-shell', count = 100, weight = 166.6667},
    {name = 'rocket', count = 100, weight = 166.6667},
    {name = 'distractor-capsule', count = 25, weight = 166.6667},
    {name = 'railgun', count = 1, weight = 100},
    {name = 'flamethrower-ammo', count = 50, weight = 100},
    {name = 'military-science-pack', count = 200, weight = 100},
    {name = 'science-pack-3', count = 200, weight = 100},
    {name = 'explosive-rocket', count = 100, weight = 100},
    {name = 'explosive-cannon-shell', count = 100, weight = 100},
    {name = 'cluster-grenade', count = 100, weight = 100},
    {name = 'poison-capsule', count = 100, weight = 100},
    {name = 'slowdown-capsule', count = 100, weight = 100},
    {name = 'construction-robot', count = 50, weight = 100},
    {name = 'solar-panel-equipment', count = 5, weight = 833.3333},
    {name = 'artillery-targeting-remote', count = 1, weight = 50},
    {name = 'tank-flamethrower', count = 1, weight = 33.3333},
    {name = 'explosive-uranium-cannon-shell', count = 100, weight = 33.3333},
    {name = 'destroyer-capsule', count = 10, weight = 33.3333},
    {name = 'artillery-shell', count = 10, weight = 25},
    {name = 'battery-equipment', count = 5, weight = 25},
    {name = 'night-vision-equipment', count = 2, weight = 25},
    {name = 'exoskeleton-equipment', count = 2, weight = 166.6667},
    {name = 'rocket-launcher', count = 1, weight = 14.2857},
    {name = 'combat-shotgun', count = 1, weight = 10},
    {name = 'flamethrower', count = 1, weight = 10},
    {name = 'tank-cannon', count = 1, weight = 10},
    {name = 'modular-armor', count = 1, weight = 100},
    {name = 'belt-immunity-equipment', count = 1, weight = 10},
    {name = 'personal-roboport-equipment', count = 1, weight = 100},
    {name = 'energy-shield-equipment', count = 2, weight = 100},
    {name = 'personal-laser-defense-equipment', count = 2, weight = 100},
    {name = 'battery-mk2-equipment', count = 1, weight = 40},
    {name = 'tank-machine-gun', count = 1, weight = 3.3333},
    {name = 'power-armor', count = 1, weight = 33.3333},
    {name = 'fusion-reactor-equipment', count = 1, weight = 33.3333},
    {name = 'production-science-pack', count = 200, weight = 100},
    {name = 'high-tech-science-pack', count = 200, weight = 100},
    {name = 'artillery-turret', count = 1, weight = 2.5},
    {name = 'artillery-wagon-cannon', count = 1, weight = 1},
    {name = 'atomic-bomb', count = 1, weight = 1},
    {name = 'space-science-pack', count = 200, weight = 10}
}

local weighted = b.prepare_weighted_array(item_pool)

local function spawn_item(entity, power)
    local i = math.random() ^ power * weighted.total
    local item = b.get_weighted_item(item_pool, weighted, i)

    entity.insert(item)
end

return function(entity, player)
    local p = entity.position
    local d = math.sqrt(p.x * p.x + p.y * p.y)

    local power = 500 / d

    for _ = 1, 3 do
        spawn_item(entity, power)
    end
end
