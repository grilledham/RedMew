local ViewModel = require 'utils.view_model'
local g = require 'utils.gui_builder'
local Event = require 'utils.event'
local Global = require 'utils.global'

local button =
    g.props({type = 'button'}):on_click(
    function(event)
        local view_model = event.view_model
        local tag = event.tag

        local old_count = view_model['count']
        view_model:set('count', old_count + tag)
    end
)
local add = button:props({caption = 'add'}):tag(1)
local remove = button:props({caption = 'remove'}):tag(-1)
local label = g.props({type = 'label'}):bind({target = 'caption', source = 'count'})

local frame = g.props({type = 'frame'}):children({add, remove, label})

local function open(event)
    local player = game.get_player(event.player_index)
    local center = player.gui.center

    local vm = ViewModel.new()
    vm.count = 10

    frame:add_to(center, vm)
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
