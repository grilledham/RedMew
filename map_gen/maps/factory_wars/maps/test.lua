local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings({MGSP.ore_oil_none, MGSP.tree_none, MGSP.cliff_none})

local ore_shape = b.throttle_world_xy(b.full_shape, 1, 16, 1, 16)
local ore = b.entity(ore_shape, 'metal-ore')

local map = b.tile('grass-1')
map = b.apply_entity(map, ore)

return map
