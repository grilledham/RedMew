local Global = require 'utils.global'
local Token = require 'utils.token'
local table = require 'utils.table'

local Public = {}
Public.__index = Public

local counter = {0}
local store = {}

Global.register(
    {counter = counter, store = store},
    function(tbl)
        counter = tbl.counter
        store = tbl.store

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

function Public.extend(new)
    local id = get_id()

    new = new or {}
    new._handlers = {}
    new._id = id

    store[id] = new

    return setmetatable(new, Public)
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

function Public.remove_on_property_changed(self, key, handler)
    local all_handlers = self._handlers
    local key_handlers = all_handlers[key]

    if not key_handlers then
        return
    end

    for i = 1, #key_handlers do
        local h = key_handlers[i].handler
        if h == handler then
            table.fast_remove(key_handlers, i)
            return
        end
    end
end

function Public.raise(self, key, value)
    local handlers = self._handlers[key]
    if not handlers then
        return
    end

    for i = 1, #handlers do
        local handler_data = handlers[i]
        local func = Token.get(handler_data.handler)
        local data = handler_data.data

        func(value, key, data)
    end
end

function Public.set(self, key, value)
    local old = self[key]
    self[key] = value

    if old ~= value then
        self:raise(key, value)
    end
end

return Public
