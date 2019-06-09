local Token = require 'utils.token'
local ObservableObject = require 'utils.observable_object'
local Store = require 'utils.gui_builder.store'
local getmetatable = getmetatable
local tostring = tostring

local Public = {}

Public.types = {
    one_time = 'one_time',
    one_way = 'one_way'
    --two_way = 'two_way',
    --one_way_to_source = 'one_way_to_source'
}

local get_from_store = Store.get_from_store
local get_view_model = Store.get_view_model
local get_item_source = Store.get_item_source
local get_view_data = Store.get_view_data
local get_tag = Store.get_tag

local function to_props_table(str)
    if type(str) == 'table' then
        return str
    end

    local result = {}
    local count = 0
    local len = #str

    local last = 1
    for i = 1, len do
        local c = str:sub(i, i)
        if c == '.' then
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

local function build_bind_getter(props)
    local count = #props

    return function(obj)
        for i = 1, count do
            if type(obj) == 'table' then
                obj = obj[props[i]]
            else
                return obj
            end
        end

        return obj
    end
end

local function build_bind_getters(props)
    local getters = {}

    for i = 1, #props do
        getters[i] = function(obj)
            if type(obj) == 'table' then
                return obj[props[i]]
            else
                return obj
            end
        end
    end

    return getters
end

local function build_bind_setter(props, convert_to)
    local count = #props

    if convert_to then
        return function(obj, value)
            for i = 1, count - 1 do
                obj = obj[props[i]]
            end

            obj[props[count]] = convert_to(value)
        end
    else
        return function(obj, value)
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

local function one_way(args)
    local context = args.context or 'view_model'
    local context_getter = context_map[context]

    local convert_to = args.convert_to

    local target = args.target
    local setter
    if type(target) == 'function' then
        setter = target
    else
        target = to_props_table(target)
        setter = build_bind_setter(target, convert_to)
    end

    local source = to_props_table(args.source)
    local getters = build_bind_getters(source)

    local getter_props_count = #source
    local handlers = {}
    local adders = {}
    local removers = {}

    for i = 1, getter_props_count do
        if i == getter_props_count then
            local getter = getters[i]
            handlers[i] =
                Token.register(
                function(obj, element)
                    local value = getter(obj)
                    setter(element, value)
                end
            )
        else
            handlers[i] =
                Token.register(
                function(obj, element, old)
                    removers[i + 1](old, element)

                    local new_value = getters[i](obj)
                    adders[i + 1](new_value, element)
                end
            )
        end

        adders[i] = function(value, element)
            for j = i, getter_props_count do
                if getmetatable(value) == ObservableObject then
                    value:on_property_changed(source[j], handlers[j], element)
                end
                value = getters[j](value)
            end

            setter(element, value)
        end

        removers[i] = function(value, element)
            for j = i, getter_props_count do
                if getmetatable(value) == ObservableObject then
                    value:remove_on_property_changed(source[j], handlers[j], element)
                end
                value = getters[j](value)
            end
        end
    end

    local add =
        Token.register(
        function(element)
            local obj = context_getter(element)
            adders[1](obj, element)
        end
    )

    local remove =
        Token.register(
        function(element)
            local obj = context_getter(element)
            removers[1](obj, element)
        end
    )

    return {add = add, remove = remove}
end

local function one_time(args)
    local context = args.context or 'view_model'
    local context_getter = context_map[context]

    local convert_to = args.convert_to

    local target = args.target
    local setter
    if type(target) == 'function' then
        setter = target
    else
        target = to_props_table(target)
        setter = build_bind_setter(target, convert_to)
    end

    local source = to_props_table(args.source)
    local getter = build_bind_getter(source)

    local add =
        Token.register(
        function(element)
            local obj = context_getter(element)
            local value = getter(obj)
            setter(element, value)
        end
    )

    return {add = add}
end

function Public.new(args)
    local bind_type = args.type or 'one_way'

    if bind_type == 'one_way' then
        return one_way(args)
    elseif bind_type == 'one_time' then
        return one_time(args)
    end
end

return Public
