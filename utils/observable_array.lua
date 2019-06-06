local Global = require 'utils.global'
local Token = require 'utils.token'
local table = require 'utils.table'

local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local fast_remove = table.fast_remove
local token_get = Token.get

local Public = {}
Public.__index = Public

local weak_table = {__mode = 'v'}

local counter = {0}
local store = setmetatable({}, weak_table)

Global.register(
    {counter = counter, store = store},
    function(tbl)
        counter = tbl.counter
        store = tbl.store

        setmetatable(store, weak_table)

        for k, v in pairs(store) do
            setmetatable(v, Public)
        end
    end
)

local function get_id()
    local count = counter[1]
    count = count + 1
    counter[1] = count
    return count
end

function Public.new()
    local id = get_id()

    local obj = {
        _handlers = {},
        _id = id,
        _array = {}
    }

    store[id] = obj

    return setmetatable(obj, Public)
end

function Public.dispose(self)
    store[self._id] = nil
end

function Public.on_array_changed(self, handler, data)
    local handlers = self._handlers
    handlers[#handlers + 1] = {handler = handler, data = data}
end

function Public.remove_on_array_changed(self, handler, data)
    local handlers = self._handlers

    for i = 1, #handlers do
        local entry = handlers[i]
        if entry.handler == handler and entry.data == data then
            fast_remove(handlers, i)
            return
        end
    end
end

function Public.raise(self, key, value)
    local handlers = self._handlers

    for i = 1, #handlers do
        local handler_data = handlers[i]
        local func = token_get(handler_data.handler)
        local data = handler_data.data

        local event = {self = self, array = self._array, data = data, key = key, value = value}
        func(event)
    end
end
local raise = Public.raise

function Public.get_array(self)
    return self._array
end

function Public.count(self)
    return #self._array
end

function Public.get(self, key)
    return self._array[key]
end

function Public.insert(self, key, value)
    local array = self._array
    local count = #array

    if value == nil then
        value = key
        key = count + 1

        array[key] = value
        raise(self, key, value)

        return
    end

    if key == count + 1 then
        array[key] = value
        raise(self, key, value)

        return
    end

    local new = value
    local current
    for i = key, count do
        current = array[i]

        array[i] = new
        raise(self, i, value)

        new = current
    end

    local old = array[key]

    if old ~= value then
        array[key] = value
        raise(self, key, value)
    end
end

function Public.remove(self, key)
    local array = self._array
    local count = #array

    for i = key, count do
        local new_value = array[i + 1]
        array[i] = new_value
        raise(self, i, new_value)
    end
end

function Public.raise_reset(self)
    raise(self)
end

return Public
