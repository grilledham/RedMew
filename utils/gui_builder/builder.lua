local Global = require 'utils.global'
local Token = require 'utils.token'
local Event = require 'utils.event'
local table = require 'utils.table'
local ObservableObject = require 'utils.observable_object'
local ObservableArray = require 'utils.observable_array'
local Store = require 'utils.gui_builder.store'
local Binding = require 'utils.gui_builder.binding'

local fast_remove = table.fast_remove

local Public = {}
Public.__index = Public

local add_to_store = Store.add_to_store
local get_from_store = Store.get_from_store
local remove_from_store = Store.remove_from_store
local get_view_model = Store.get_view_model
local get_item_source = Store.get_item_source
local get_view_data = Store.get_view_data
local get_tag = Store.get_tag

Public.get_data = get_from_store
Public.get_view_model = get_view_model
Public.get_item_source = get_item_source
Public.get_view_data = get_view_data
Public.get_tag = get_tag

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
    if value == nil then
        return tbl
    end

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

function Public.add_to(template, parent, data)
    data = data or {}

    local element = parent.add(template._props)

    local element_data = {
        template = template,
        tag = data.tag or template._tag,
        view_data = data.view_data,
        view_model = data.view_model
    }
    add_to_store(element, element_data)

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
            local a = add[i]
            a = Token.get(a)
            a(element, element_data)
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
    if data then
        local template = data.template

        local remove = template._remove
        if remove then
            for i = 1, #remove do
                local r = remove[i]
                r = Token.get(r)
                r(element, data)
            end
        end

        remove_from_store(element)
    end

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

local event_mt = {
    view_data = function(self)
        return get_view_data(self.element)
    end,
    item_source = function(self)
        return get_item_source(self.element)
    end,
    view_model = function(self)
        return get_view_model(self.element)
    end,
    tag = function(self)
        return get_tag(self.element)
    end
}
function event_mt.__index(self, key)
    return event_mt[key](self)
end

local function handler_factory(event_id)
    Store.event_handlers[event_id] = {}

    local function add_handler(element, handler_token)
        local handlers = Store.event_handlers[event_id]
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
        local handlers = Store.event_handlers[event_id]
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
        local handlers = Store.event_handlers[event_id]

        local element = event.element
        if not element or not element.valid then
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

        setmetatable(event, event_mt)

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

        local add =
            Token.register(
            function(e)
                add_handler(e, token)
            end
        )

        local remove =
            Token.register(
            function(e)
                remove_handler(e, token)
            end
        )

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

    callback = Token.register(callback)

    local new_add = append(template._add, callback)
    return create_new(template, {_add = new_add})
end

function Public.on_remove(template, callback)
    if not callback then
        callback = template
        template = default_template
    end

    callback = Token.register(callback)

    local new_remove = append(template._remove, callback)
    return create_new(template, {_remove = new_remove})
end

function Public.children(template, children)
    if not children then
        children = template
        template = default_template
    end

    local add =
        Token.register(
        function(element)
            for i = 1, #children do
                children[i]:add_to(element)
            end
        end
    )

    local new_add = append(template._add, add)
    return create_new(template, {_add = new_add})
end

function Public.tag(template, tag)
    if not tag then
        tag = template
        template = default_template
    end

    return create_new(template, {_tag = tag})
end

function Public.view_data(template, view_data)
    if not view_data then
        view_data = template
        template = default_template
    end

    local func
    if type(view_data) == 'function' then
        func = function(element, data)
            data.view_data = view_data(element, data)
        end
    else
        func = function(_, data)
            data.view_data = view_data
        end
    end

    add = Token.register(func)
    local new_add = append(template._add, add)

    return create_new(template, {_add = new_add})
end

function Public.view_model(template, view_model)
    if not view_model then
        view_model = template
        template = default_template
    end

    local func
    if type(view_model) == 'function' then
        func = function(element, data)
            data.view_model = view_data(element, data)
        end
    else
        func = function(_, data)
            data.view_model = view_model
        end
    end

    add = Token.register(func)
    local new_add = append(template._add, add)

    return create_new(template, {_add = new_add})
end

function Public.bind(template, args)
    if not args then
        args = template
        template = default_template
    end

    local binding = Binding.new(args)

    local new_add = append(template._add, binding.add)
    local new_remove = append(template._remove, binding.remove)

    return create_new(template, {_add = new_add, _remove = new_remove})
end

local function item_source_setter(element, item_source)
    local element_data = get_from_store(element)
    local template = element_data.template
    data = template._item_templates_data

    if data == nil then
        return
    end

    local add, remove = data.add, data.remove
    add, remove = Token.get(add), Token.get(remove)

    --remove(element)

    element_data.item_source = item_source

    --add(element)
end

function Public.item_source(template, item_source)
    if not item_source then
        item_source = template
        template = default_template
    end

    local t = type(item_source)

    if t == 'table' then
        item_source.target = item_source_setter
    elseif t == 'string' then
        item_source = {source = item_source, target = item_source_setter}
    else
        error('item_source must be a table or string.', 2)
    end

    local binding = Binding.new(item_source)

    local new_add = append(template._add, binding.add)
    local new_remove = append(template._remove, binding.remove)

    return create_new(template, {_add = new_add, _remove = new_remove})
end

local function template_bounds(index, templates_count)
    local upper = index * templates_count
    local lower = upper - templates_count + 1

    return lower, upper
end

function Public.item_templates(template, templates)
    if not templates then
        templates = template
        template = default_template
    end

    local templates_count = #templates

    local handler =
        Token.register(
        function(event)
            local array = event.array
            local key = event.key
            local value = event.value
            local element = event.data
            local children = element.children

            -- reset
            if key == nil then
                for i = 1, #children do
                    Public.destroy(element.children[i])
                end

                for i = 1, #array do
                    for j = 1, templates_count do
                        local item = array[i]
                        local temp = templates[j]

                        local flow = element.add {type = 'flow'}
                        temp:add_to(flow, {view_model = item})
                    end
                end

                return
            end

            local l, u = template_bounds(key, templates_count)

            -- remove row
            if value == nil then
                for i = l, u do
                    Public.destroy(children[i])
                end

                return
            end

            -- update row
            if children[l] then
                for i = l, u do
                    Public.destroy(children[i].children[1])
                end

                local i = l
                for j = 1, templates_count do
                    local temp = templates[j]

                    local flow = children[i]
                    temp:add_to(flow, {view_model = value})

                    i = i + 1
                end

                return
            end

            -- add row
            for j = 1, templates_count do
                local temp = templates[j]

                local flow = element.add {type = 'flow'}
                temp:add_to(flow, {view_model = value})
            end
        end
    )

    local add =
        Token.register(
        function(element)
            local item_source = get_item_source(element)
            d = (serpent.block(item_source))

            if item_source == nil then
                return
            end

            if getmetatable(item_source) == ObservableArray then
                item_source:on_array_changed(handler, element)
                item_source = item_source._array
            end

            for i = 1, #item_source do
                for j = 1, templates_count do
                    local item = item_source[i]
                    local temp = templates[j]

                    local flow = element.add {type = 'flow'}
                    temp:add_to(flow, {view_model = item})
                end
            end
        end
    )

    local remove =
        Token.register(
        function(element)
            local item_source = get_item_source(element)

            if item_source == nil then
                return
            end

            if getmetatable(item_source) == ObservableArray then
                item_source:remove_on_array_changed(handler, element)
            end

            local children = element.children
            for i = 1, #children do
                local child = children[i]
                Public.destroy(child)
            end
        end
    )

    local new_add = append(template._add, add)
    local new_remove = append(template._remove, remove)
    local item_templates_data = {add = add, remove = remove}

    return create_new(template, {_add = new_add, _remove = new_remove, _item_templates_data = item_templates_data})
end

return Public
