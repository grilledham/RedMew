local ObservableObject = require 'utils.observable_object'
local Global = require 'utils.global'
local g = require 'utils.gui_builder'

local player_view_models = {}

Global.register(
    player_view_models,
    function(tbl)
        player_view_models = tbl
    end
)

local function get_view_model(player_index)
    local vm = player_view_models[player_index]

    if not vm then
        vm = ObservableObject.new()
        vm['color'] = {r = 0, g = 0, b = 0, a = 255}
        player_view_models[player_index] = vm
    end

    return vm
end

local slider =
    g.props({type = 'slider', minimum_value = 0, maximum_value = 255}):on_value_changed(
    function(event)
        local element = event.element
        local channel = event.tag
        local view_model = event.view_model

        local value = math.round(element.slider_value, 0)
        local color = view_model['color']
        color[channel] = value

        view_model:raise('color')
    end
)

local label = g.props({type = 'label'})
local flow = g.props({type = 'flow'})

local channels = {'r', 'g', 'b', 'a'}
local rows = {}

for i, channel in ipairs(channels) do
    local source = {'color', channel}

    local l = label:props({caption = channel})
    local s = slider:tag(channel):bind({target = 'slider_value', source = source})
    local out_label = label:bind({target = 'caption', source = source})

    rows[i] = flow:children({l, s, out_label})
end

local sample = label:props({caption = 'Sample text.'}):bind({target = 'style.font_color', source = 'color'})

rows[#rows + 1] = sample

local frame = g.props({type = 'frame', direction = 'vertical'}):children(rows)
local mega_frame = g.props({type = 'frame'}):children({frame, frame, frame})

function open()
    local player = game.player

    local vm = get_view_model(player.index)

    local center = player.gui.center
    frame:add_to(center, vm)
end

function close()
    local center = game.player.gui.center
    local fe = center.children[1]

    --g.get_view_model(fe):dispose()

    g.destroy(fe)
end
