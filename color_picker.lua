local ObservableObject = require 'utils.observable_object'
local ObservableArray = require 'utils.observable_array'
local Global = require 'utils.global'
local Event = require 'utils.event'
local g = require 'utils.gui_builder.builder'

local player_view_models = {}

Global.register(
    player_view_models,
    function(tbl)
        player_view_models = tbl
    end
)

local function color_view_model()
    local vm = ObservableObject.new()
    vm['color'] = {r = 0, g = 0, b = 0, a = 255}
    vm['text'] = 'Sample Text'

    return vm
end

local function get_view_model(player_index)
    local vm = player_view_models[player_index]

    if not vm then
        vm = ObservableObject.new()

        local colors = ObservableArray.new()
        colors:insert(color_view_model())
        vm['colors'] = colors

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

local sample_base = g.bind({target = 'style.font_color', source = 'color'})

local sample_textfield =
    sample_base:props({type = 'textfield'}):bind({target = 'text', source = 'text'}):on_text_changed(
    function(event)
        local element = event.element
        local view_model = event.view_model

        view_model['text'] = element.text
    end
)

local sample_label = sample_base:props({type = 'label'}):bind({target = 'caption', source = 'text'})

local sample_row = g.props({type = 'flow', direction = 'vertical'}):children({sample_textfield, sample_label})

rows[#rows + 1] = sample_row

local color_picker = g.props({type = 'flow', direction = 'vertical'}):children(rows)

local list_view = g.props({type = 'flow', direction = 'vertical'}):item_source('colors'):item_templates({color_picker})

local function add(event)
    local view_model = event.view_model
    local colors = view_model.colors

    colors:insert(color_view_model())
end

local function remove(event)
    local view_model = event.view_model
    local colors = view_model.colors

    colors:remove(1)
end

local button_base = g.props({type = 'button'})
local add_button = button_base:props({caption = 'add'}):on_click(add)
local remove_button = button_base:props({caption = 'remove'}):on_click(remove)
local button_flow = g.props({type = 'flow', direction = 'horizontal'}):children({add_button, remove_button})

local frame = g.props({type = 'frame', direction = 'vertical'}):children({button_flow, list_view})
--local mega_frame = g.props({type = 'frame'}):children({frame, frame, frame})

function open(event)
    local player = game.get_player(event.player_index)

    local vm = get_view_model(player.index)

    local center = player.gui.center
    frame:add_to(center, {view_model = vm})
end

function close(event)
    local player = game.get_player(event.player_index)

    local center = player.gui.center
    local fe = center.children[1]

    g.destroy(fe)
end

local open_button = g.props({type = 'button', caption = 'open'}):on_click(open)
local close_button = g.props({type = 'button', caption = 'close'}):on_click(close)

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = game.get_player(event.player_index)

        local top = player.gui.top
        open_button:add_to(top)
        close_button:add_to(top)
    end
)
