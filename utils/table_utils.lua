local Iterable = {}
Iterable.__index = Iterable

function Iterable:to_table()
    local iterator = self:get_iterator()
    local result = {}
    local key, value = iterator()
    while key ~= nil do
        result[key] = value
        key, value = iterator()
    end

    return result
end

function Iterable:filter(predicate)
    local function get_iterator()
        local iter = self:get_iterator()
        local key, value

        return function()
            key, value = iter()
            while key ~= nil do
                if (predicate(key, value)) then
                    return key, value
                end
                key, value = iter()
            end
        end
    end

    return setmetatable({get_iterator = get_iterator}, Iterable)
end

function Iterable:map(project)
    local function get_iterator()
        local iter = self:get_iterator()
        return function()
            local key, value = iter()
            if key ~= nil then
                return project(key, value)
            end
        end
    end

    return setmetatable({get_iterator = get_iterator}, Iterable)
end

function Iterable:foreach(action)
    for k, v in self:get_iterator() do
        action(k, v)
    end
end

table.__index = table
setmetatable(table, Iterable)

function table.new(tbl)
    return setmetatable(tbl or {}, table)
end

function table:get_iterator()
    local key, value
    return function()
        key, value = next(self, key)
        return key, value
    end
end

local function predicate(k, v)
    return v < 3
end

local function project(k, v)
    return k, v * 2
end

local function action(k, v)
    print(k .. ' : ' .. v)
end

local t = table.new({1, 2, 3})

local query1 = t:filter(predicate)
query1:foreach(action)
query1:foreach(action)
query1:map(project):foreach(action)
local t2 = t:to_table()

for k, v in pairs(t2) do
    action(k, v)
end

return Iterable
