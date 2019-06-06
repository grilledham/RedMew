local Global = require 'utils.global'
local Token = require 'utils.token'
local table = require 'utils.table'

local setmetatable = setmetatable
local rawget = rawget
local fast_remove = table.fast_remove
local token_get = Token.get

local Public = {}

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
        _props = {}
    }

    store[id] = obj

    return setmetatable(obj, Public)
end

function Public.dispose(self)
    store[self._id] = nil
end

function Public.on_property_changed(self, key, handler, data)
    local all_handlers = self._handlers
    local key_handlers = all_handlers[key]

    if not key_handlers then
        key_handlers = {}
        all_handlers[key] = key_handlers
    end

    key_handlers[#key_handlers + 1] = {handler = handler, data = data}
end

function Public.remove_on_property_changed(self, key, handler, data)
    local all_handlers = self._handlers
    local key_handlers = all_handlers[key]

    if not key_handlers then
        return
    end

    for i = 1, #key_handlers do
        local entry = key_handlers[i]
        if entry.handler == handler and entry.data == data then
            fast_remove(key_handlers, i)
            return
        end
    end
end

function Public.raise(self, key)
    local handlers = self._handlers[key]
    if not handlers then
        return
    end

    for i = 1, #handlers do
        local handler_data = handlers[i]
        local func = token_get(handler_data.handler)
        local data = handler_data.data

        func(self, data, key)
    end
end
local raise = Public.raise

function Public.__index(obj, key)
    return rawget(Public, key) or obj._props[key]
end

function Public.__newindex(obj, key, value)
    local props = obj._props
    local old = props[key]

    if old ~= value then
        props[key] = value
        raise(obj, key)
    end
end

return Public
