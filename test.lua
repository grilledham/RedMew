local ViewModelBase = require 'utils.view_model_base'
local g = require 'utils.gui_builder'

local vm = ViewModelBase.extend({})
vm.count = 0

local base = g.view_model(vm)

local button = base:props({type = 'button'}):style({font = 'default-large-bold', height = 64, width = 128})
local add_button =
    button:on_click(
    function(event)
        local element = event.element
        local data = g.get_data(element)
        local amount = data.amount
        local view_model = data.view_model

        local old_count = view_model.count
        view_model:set('count', old_count + amount)
    end
)

local buttons = {}

for i = 1, 9 do
    buttons[#buttons + 1] = add_button:props({caption = i}):view_data({amount = i})
end

local grid = g.props({type = 'table', column_count = 3}):children(buttons)

local label =
    base:props({type = 'label'}):style(
    {
        horizontal_align = 'right',
        vertical_align = 'center',
        font = 'default-large-bold'
    }
):bind('caption', 'count')

local expand_flow = g.props({type = 'flow'}):style({horizontally_stretchable = true})
local label_flow = g.props({'flow'}):children({expand_flow, label})

local frame = g.props({type = 'frame', direction = 'vertical'}):children({label_flow, grid})

function open()
    local center = game.player.gui.center
    frame:add_to(center)
end

function close()
    local center = game.player.gui.center
    local fe = center.children[1]

    g.destroy(fe)
end
