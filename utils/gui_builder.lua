local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Event = require 'utils.event'
local table = require 'utils.table'

local fast_remove = table.fast_remove

local Public = {}
Public.__index = Public

local store = {}
local event_handlers = {}

Global.register(
    {
        store = store,
        event_handlers = event_handlers
    },
    function(tbl)
        store = tbl.store
        event_handlers = tbl.event_handlers
    end
)

local function combine(tbl1, tbl2)
    local result = {}

    if tbl1 then
        for k, v in pairs(tbl1) do
            result[k] = v
        end
    end
    if tbl2 then
        for k, v in pairs(tbl2) do
            result[k] = v
        end
    end

    return result
end

local function append(tbl, value)
    local result = {}
    local count = 1

    if tbl then
        for i = 1, #tbl do
            result[count] = tbl[i]
            count = count + 1
        end
    end

    result[count] = value

    return result
end

local function create_new(tbl1, tbl2)
    local new = combine(tbl1, tbl2)
    return setmetatable(new, Public)
end

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

local function remove_from_store(element)
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

Public.get_data = get_from_store

function Public.add_to(template, parent)
    local element = parent.add(template._props)

    local data = {template = template}

    local vmp = template._view_model_provider
    local vmpt = type(vmp)

    if vmpt == 'table' then
        data.view_model = vmp
    elseif vmpt == 'function' then
        data.view_model = vmp(element, template)
    elseif vmp ~= nil then
        error('view_model must be a table or function', 2)
    end

    local vdp = template._view_data_provider
    local vdpt = type(vdp)

    if vdpt == 'table' then
        for k, v in pairs(vdp) do
            data[k] = v
        end
    elseif vdpt == 'function' then
        local view_data = vdp(element, template)
        for k, v in pairs(view_data) do
            data[k] = v
        end
    elseif vdp ~= nil then
        error('view_data must be a table or function', 2)
    end

    add_to_store(element, data)

    local style = template._style
    if style then
        local es = element.style
        for k, v in pairs(style) do
            es[k] = v
        end
    end

    local add = template._add
    if add then
        for i = 1, #add do
            add[i](template, element)
        end
    end

    return element
end

function Public.destroy(element)
    local children = element.children
    for i = 1, #children do
        local child = children[i]
        Public.destroy(child)
    end

    local data = get_from_store(element)
    local template = data.template

    local remove = template._remove
    if remove then
        for i = 1, #remove do
            remove[i](template, element)
        end
    end

    remove_from_store(element)

    element.destroy()
end

local default_template = {_props = {type = 'flow'}}

function Public.props(template, props)
    if not props then
        props = template
        template = default_template
    end

    local new_props = combine(template._props, props)
    return create_new(template, {_props = new_props})
end

function Public.style(template, style)
    if not style then
        style = template
        template = default_template
    end

    local new_style = combine(template._style, style)
    return create_new(template, {_style = new_style})
end

local function handler_factory(event_id)
    local handlers = {}
    event_handlers[event_id] = handlers

    local function add_handler(element, handler_token)
        local pi, ei = element.player_index, element.index

        local player_handlers = handlers[pi]
        if not player_handlers then
            player_handlers = {}
            handlers[pi] = player_handlers
        end

        local element_handlers = player_handlers[ei]
        if not element_handlers then
            element_handlers = {}
            player_handlers[ei] = element_handlers
        end

        element_handlers[#element_handlers + 1] = handler_token
    end

    local function remove_handler(element, handler_token)
        local pi, ei = element.player_index, element.index

        local player_handlers = handlers[pi]
        if not player_handlers then
            return
        end

        local element_handlers = player_handlers[ei]
        if not element_handlers then
            return
        end

        for i = 1, #element_handlers do
            local ht = element_handlers[i]
            if ht == handler_token then
                fast_remove(element_handlers, i)
                break
            end
        end

        if next(element_handlers) == nil then
            player_handlers[ei] = nil
            if next(player_handlers) == nil then
                handlers[pi] = nil
            end
        end
    end

    local function raise_handlers(event)
        local element = event.element
        if not element.valid then
            return
        end

        local pi, ei = element.player_index, element.index

        local player = game.get_player(pi)
        if not player or not player.valid then
            return
        end

        event.player = player

        local player_handlers = handlers[pi]
        if not player_handlers then
            return
        end

        local element_handlers = player_handlers[ei]
        if not element_handlers then
            return
        end

        for i = 1, #element_handlers do
            local ht = element_handlers[i]
            local func = Token.get(ht)
            func(event)
        end
    end

    Event.add(event_id, raise_handlers)

    return function(template, handler)
        if not handler then
            handler = template
            template = default_template
        end

        local token = Token.register(handler)

        local function add(_, e)
            add_handler(e, token)
        end
        local function remove(_, e)
            remove_handler(e, token)
        end

        local new_add = append(template._add, add)
        local new_remove = append(template._remove, remove)

        return create_new(template, {_add = new_add, _remove = new_remove})
    end
end

Public.on_checked_state_changed = handler_factory(defines.events.on_gui_checked_state_changed)
Public.on_click = handler_factory(defines.events.on_gui_click)
Public.on_custom_close = handler_factory(defines.events.on_gui_closed)
Public.on_elem_changed = handler_factory(defines.events.on_gui_elem_changed)
Public.on_selection_state_changed = handler_factory(defines.events.on_gui_selection_state_changed)
Public.on_text_changed = handler_factory(defines.events.on_gui_text_changed)
Public.on_value_changed = handler_factory(defines.events.on_gui_value_changed)

function Public.on_add(template, callback)
    if not callback then
        callback = template
        template = default_template
    end

    local new_add = append(template._add, callback)
    return create_new(template, {_add = new_add})
end

function Public.on_remove(template, callback)
    if not callback then
        callback = template
        template = default_template
    end

    local new_remove = append(template._remove, callback)
    return create_new(template, {_remove = new_remove})
end

function Public.children(template, children)
    if not children then
        children = template
        template = default_template
    end

    local function add(t, element)
        for i = 1, #children do
            children[i]:add_to(element)
        end
    end

    local new_add = append(template._add, add)
    return create_new(template, {_add = new_add})
end

function Public.view_model(template, view_model)
    if not view_model then
        view_model = template
        template = default_template
    end

    return create_new(template, {_view_model_provider = view_model})
end

function Public.view_data(template, view_data)
    if not view_data then
        view_data = template
        template = default_template
    end

    return create_new(template, {_view_data_provider = view_data})
end

function Public.bind(template, element_prop, source_prop)
    if not source_prop then
        source_prop = element_prop
        element_prop = template
        template = default_template
    end

    local handler =
        Token.register(
        function(value, key, element)
            element[element_prop] = value
        end
    )

    local function add(t, element)
        local data = get_from_store(element)
        local view_model = data.view_model

        view_model:on_property_changed(source_prop, handler, element)

        element[element_prop] = view_model[source_prop]
    end

    local function remove(t, element)
        local data = get_from_store(element)
        local view_model = data.view_model
        view_model:remove_on_property_changed(source_prop, handler)
    end

    local new_add = append(template._add, add)
    local new_remove = append(template._remove, remove)

    return create_new(template, {_add = new_add, _remove = new_remove})
end

function Public.bind_style(template, style_prop, source_prop)
    if not source_prop then
        source_prop = style_prop
        style_prop = template
        template = default_template
    end

    local handler =
        Token.register(
        function(value, key, element)
            element.style[style_prop] = value
        end
    )

    local function add(t, element)
        local data = get_from_store(element)
        local view_model = data.view_model

        view_model:on_property_changed(source_prop, handler, element)

        element.style[style_prop] = view_model[source_prop]
    end

    local function remove(t, element)
        local data = get_from_store(element)
        local view_model = data.view_model
        view_model:remove_on_property_changed(source_prop, handler)
    end

    local new_add = append(template._add, add)
    local new_remove = append(template._remove, remove)

    return create_new(template, {_add = new_add, _remove = new_remove})
end

return Public
