local Global = require 'utils.global'
local Token = require 'utils.token'
local Event = require 'utils.event'
local table = require 'utils.table'
local ObservableObject = require 'utils.observable_object'

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

local function get_view_model(element)
    local data = get_from_store(element)
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

local function get_view_data(element)
    local data = get_from_store(element)
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

local function get_tag(element)
    local data = get_from_store(element)
    return data.tag
end
Public.get_tag = get_tag

function Public.add_to(template, parent, view_model)
    local element = parent.add(template._props)

    local data = {template = template}

    local vmt = type(view_model)

    if vmt == 'table' then
        data.view_model = view_model
    elseif vmt == 'function' then
        data.view_model = view_model(element, data)
    elseif view_model ~= nil then
        error('view_model must be a table or function', 2)
    end

    local vd = template._view_data
    if vd then
        vd = Token.get(vd)
        data.view_data = vd(element, data)
    end

    data.tag = template._tag

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
            local a = add[i]
            a = Token.get(a)
            a(element, data)
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
            local r = remove[i]
            r = Token.get(r)
            r(element, data)
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

local event_mt = {
    view_data = function(self)
        return get_view_data(self.element)
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
    event_handlers[event_id] = {}

    local function add_handler(element, handler_token)
        local handlers = event_handlers[event_id]
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
        local handlers = event_handlers[event_id]
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
        local handlers = event_handlers[event_id]

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

function Public.view_data(template, view_data_getter)
    if not view_data_getter then
        view_data_getter = template
        template = default_template
    end

    view_data_getter = Token.register(view_data_getter)

    return create_new(template, {_view_data = view_data_getter})
end

function Public.tag(template, tag)
    if not tag then
        tag = template
        template = default_template
    end

    return create_new(template, {_tag = tag})
end

local function split(str, char)
    if type(str) == 'table' then
        return str
    end

    local result = {}
    local count = 0
    local len = #str

    local last = 1
    for i = 1, len do
        local c = str:sub(i, i)
        if c == char then
            local sub = str:sub(last, i - 1)
            last = i + 1

            if sub ~= '' then
                count = count + 1
                result[count] = sub
            end
        end
    end

    if len >= last then
        result[count + 1] = str:sub(last, len)
    end

    return result
end

local function build_bind_getter(props, convert_from)
    local count = #props

    if convert_from then
        return function(obj)
            for i = 1, count do
                obj = obj[props[i]]
            end

            return convert_from(obj)
        end
    else
        return function(obj)
            for i = 1, count do
                obj = obj[props[i]]
            end
            return obj
        end
    end
end

local function build_bind_setter(props, convert_to)
    local count = #props

    if convert_to then
        return function(value, obj)
            for i = 1, count - 1 do
                obj = obj[props[i]]
            end

            obj[props[count]] = convert_to(value)
        end
    else
        return function(value, obj)
            for i = 1, count - 1 do
                obj = obj[props[i]]
            end

            obj[props[count]] = value
        end
    end
end

local context_map = {
    ['view_model'] = get_view_model,
    ['view_data'] = get_view_data,
    ['tag'] = get_tag,
    ['self'] = function(element)
        return element
    end
}

function Public.bind(template, args)
    local context = args.context or 'view_model'
    local target = split(args.target, '.')
    local source = split(args.source, '.')
    local convert_to = args.convert_to
    --local convert_from = args.convert_from

    local key = source[1]
    local getter = build_bind_getter(source)
    local setter = build_bind_setter(target, convert_to)
    local context_getter = context_map[context]

    local handler =
        Token.register(
        function(obj, element)
            local value = getter(obj)
            setter(value, element)
        end
    )

    local add =
        Token.register(
        function(element)
            local obj = context_getter(element)
            if getmetatable(obj) == ObservableObject then
                obj:on_property_changed(key, handler, element)
            end

            local value = getter(obj)
            setter(value, element)
        end
    )

    local remove =
        Token.register(
        function(element)
            local obj = context_getter(element)
            if getmetatable(obj) == ObservableObject then
                obj:remove_on_property_changed(key, handler)
            end
        end
    )

    local new_add = append(template._add, add)
    local new_remove = append(template._remove, remove)

    return create_new(template, {_add = new_add, _remove = new_remove})
end

return Public
