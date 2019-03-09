local Debug = require 'features.gui.debug.model'
local Event = require 'utils.event'
local Color = require 'resources.color_presets'

local dump = Debug.dump
local function game_dump(data)
    game.print(dump(data))
end
local draw_rectangle = rendering.draw_rectangle

function spawn()
    local player = game.player
    local surface = player.surface

    surface.create_entity {name = 'small-biter', force = 'player', position = player.position}
end

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = game.get_player(event.player_index)
        player.character.destroy()
        player.insert('selection-tool')
    end
)

Event.add(
    defines.events.on_player_selected_area,
    function(event)
        local area = event.area
        local player = game.get_player(event.player_index)
        local surface = player.surface

        local entities = surface.find_entities_filtered {area = area}

        for i = 1, #entities do
            local e = entities[i]
            local p = e.position
            local px, py = p.x, p.y
            local bb = e.selection_box
            local lt, rb = bb.left_top, bb.right_bottom
            lt.x = lt.x - px
            lt.y = lt.y - py
            rb.x = rb.x - px
            rb.y = rb.y - py
            local args = {
                color = Color.green,
                filled = false,
                left_top = e,
                left_top_offset = lt,
                right_bottom = e,
                right_bottom_offset = rb,
                surface = surface,
                time_to_live = 180
            }

            draw_rectangle(args)
        end
    end
)
