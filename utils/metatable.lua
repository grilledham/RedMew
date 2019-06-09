local Public = {}

local Global = require 'utils.global'
local setmetatable = setmetatable
local pairs = pairs

local weak_table = {__mode = 'k'}

local store = setmetatable({}, weak_table)

Global.register(
    {store = store},
    function(tbl)
        store = tbl.store
        setmetatable(store, weak_table)

        for k, v in pairs(store) do
            setmetatable(k, v)
        end
    end
)

function Public.setmetatable(obj, metatable)
    store[obj] = metatable
    return setmetatable(obj, metatable)
end

function Public.dispose(obj)
    store[obj] = nil
end

return Public
