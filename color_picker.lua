local ViewModelBase = require 'utils.view_model_base'
local g = require 'utils.gui_builder'

local function make_color(vm)
    return {r = vm.r, g = vm.g, b = vm.b, a = vm.a}
end

local vm = ViewModelBase.extend()
vm.r = 0
vm.g = 0
vm.b = 0
vm.a = 255
vm.color = {r = 0, g = 0, b = 0, a = 255}

local base = g.view_model(vm)
local slider =
    base:props({type = 'slider', minimum_value = 0, maximum_value = 255}):on_value_changed(
    function(event)
        local element = event.element
        local data = g.get_data(element)
        local channel = data.channel
        local view_model = data.view_model

        local value = math.round(element.slider_value, 0)
        local color = make_color(view_model)

        view_model:set(channel, value)
        view_model:set('color', color)
    end
):on_add(
    function(t, element)
        local data = g.get_data(element)
        local channel = data.channel
        local view_model = data.view_model

        local value = view_model[channel]
        element.slider_value = value
    end
)

local label = base:props({type = 'label'})
local flow = g.props({type = 'flow'})

local channels = {'r', 'g', 'b', 'a'}

local rows = {}

for i, channel in ipairs(channels) do
    local view_data = {channel = channel}
    local l = label:props({caption = channel})
    local out_label = label:view_data(view_data):bind('caption', channel)
    local s = slider:view_data(view_data)

    rows[i] = flow:children({l, s, out_label})
end

local sample = label:props({caption = 'Sample text.'}):bind_style('font_color', 'color')
rows[#rows + 1] = sample

local frame = g.props({type = 'frame', direction = 'vertical'}):children(rows)

function open()
    local center = game.player.gui.center
    frame:add_to(center)
end

function close()
    local center = game.player.gui.center
    local fe = center.children[1]

    g.destroy(fe)
end
