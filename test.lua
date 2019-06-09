local ObservableObject = require 'utils.observable_object'
local Event = require 'utils.event'
local Global = require 'utils.global'
local g = require 'utils.gui_builder.builder'

vm = ObservableObject.new()
vm.text = 'text'

local textfield =
    g.props({type = 'textfield'}):on_text_changed(
    function(event)
        local vm = event.view_model
        vm.text = event.element.text
    end
):bind({target = 'text', source = 'text'})
local label = g.props({type = 'label'}):bind({target = 'caption', source = 'text'})

local frame = g.props({type = 'frame', direction = 'vertical'}):children({textfield, label})

local function open(event)
    local player = game.get_player(event.player_index)
    local center = player.gui.center

    frame:add_to(center, {view_model = vm})
end

local function close(event)
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
