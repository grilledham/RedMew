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

local function item_view_model()
    local vm = ObservableObject.new()
    vm['name'] = 'name'
    vm['age'] = 20

    return vm
end

local function get_view_model(player_index)
    local vm = player_view_models[player_index]

    if not vm then
        vm = ObservableObject.new()

        local items = ObservableArray.new()
        items:insert(item_view_model())
        vm['items'] = items

        vm.name_visible = true
        vm.age_visible = true

        player_view_models[player_index] = vm
    end

    return vm
end

local base_textfield =
    g.props({type = 'textfield'}):on_text_changed(
    function(event)
        local tag = event.tag
        local vm = event.view_model
        local e = event.element

        vm[tag] = e.text
    end
)
local base_button = g.props({type = 'button'})

local columns = {}
columns[1] =
    base_textfield:tag('name'):bind({target = 'text', source = 'name'}):bind(
    {context = 'view_data', target = 'visible', source = 'name_visible'}
)
columns[2] =
    base_textfield:tag('age'):bind({target = 'text', source = 'age'}):bind(
    {context = 'view_data', target = 'visible', source = 'age_visible'}
)
columns[3] =
    base_button:props({caption = 'remove'}):on_click(
    function(event)
        local vd = event.view_data
        local item = event.view_model

        vd.items:remove_value(item)
    end
)

local grid = g.props({type = 'table', column_count = #columns}):item_source('items'):item_templates(columns)

local add =
    base_button:props({caption = 'add'}):on_click(
    function(event)
        local vm = event.view_model
        vm.items:insert(item_view_model())
    end
)

local function show_hide_converter(value)
    if value then
        return 'hide'
    else
        return 'show'
    end
end

local name_button =
    base_button:bind(
    {
        target = 'caption',
        source = 'name_visible',
        convert_to = function(value)
            return 'name - ' .. show_hide_converter(value)
        end
    }
):on_click(
    function(event)
        local vm = event.view_model
        vm.name_visible = not vm.name_visible
    end
)

local age_button =
    base_button:bind(
    {
        target = 'caption',
        source = 'age_visible',
        convert_to = function(value)
            return 'age - ' .. show_hide_converter(value)
        end
    }
):on_click(
    function(event)
        local vm = event.view_model
        vm.age_visible = not vm.age_visible
    end
)

local top_flow = g.props({type = 'flow'}):children({name_button, age_button})

local frame = g:props({type = 'frame', direction = 'vertical'}):children({top_flow, grid, add})

function open(event)
    local player = game.get_player(event.player_index)

    local vm = get_view_model(player.index)

    local center = player.gui.center
    frame:add_to(center, {view_model = vm, view_data = vm})
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
