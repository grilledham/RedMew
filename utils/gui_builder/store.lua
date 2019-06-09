local Global = require 'utils.global'

local Public = {}

local store = {}
Public.event_handlers = {}

Global.register(
    {
        store = store,
        event_handlers = Public.event_handlers
    },
    function(tbl)
        store = tbl.store
        Public.event_handlers = tbl.event_handlers
    end
)

local function add_to_store(element, data)
    local pi = element.player_index
    local ei = element.index

    local player_store = store[pi]
    if not player_store then
        player_store = {}
        store[pi] = player_store
    end

    player_store[ei] = data
end
Public.add_to_store = add_to_store

function Public.remove_from_store(element)
    local pi = element.player_index
    local ei = element.index

    local player_store = store[pi]
    if not player_store then
        return
    end

    player_store[ei] = nil
end

local function get_from_store(element)
    local pi = element.player_index
    local ei = element.index

    local player_store = store[pi]
    if not player_store then
        return nil
    end

    return player_store[ei]
end
Public.get_from_store = get_from_store

local function get_view_model(element)
    if element == nil then
        return
    end

    local data = get_from_store(element)

    if not data then
        return get_view_model(element.parent)
    end

    local view_model = data.view_model
    if view_model ~= nil then
        return view_model
    end

    view_model = get_view_model(element.parent)
    if view_model ~= nil then
        data.view_model = view_model
    end

    return view_model
end
Public.get_view_model = get_view_model

local function get_item_source(element)
    if element == nil then
        return
    end

    local data = get_from_store(element)

    if not data then
        return get_item_source(element.parent)
    end

    local item_source = data.item_source
    if item_source ~= nil then
        return item_source
    end

    item_source = get_item_source(element.parent)
    if item_source ~= nil then
        data.item_source = item_source
    end

    return item_source
end
Public.get_item_source = get_item_source

local function get_view_data(element)
    if element == nil then
        return
    end

    local data = get_from_store(element)

    if not data then
        return get_view_data(element.parent)
    end

    local view_data = data.view_data
    if view_data ~= nil then
        return view_data
    end

    view_data = get_view_data(element.parent)
    if view_data ~= nil then
        data.view_data = view_data
    end

    return view_data
end
Public.get_view_data = get_view_data

function Public.get_tag(element)
    local data = get_from_store(element)
    return data.tag
end

return Public
