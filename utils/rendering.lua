local Public = {}

local cos = math.cos
local sin = math.sin

local rendering = rendering
local draw_polygon = rendering.draw_polygon

function Public.draw_polygon(positions, options)
    local vertices = {}

    for i = 1, #positions do
        vertices[i] = {target = positions[i]}
    end

    local args = {vertices = vertices}
    for k, v in pairs(options) do
        args[k] = v
    end

    return draw_polygon(args)
end

function Public.translate(positions, x, y)
    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        result[i] = {pos[1] + x, pos[2] + y}
    end

    return result
end

function Public.scale(positions, x, y)
    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        result[i] = {pos[1] * x, pos[2] * y}
    end

    return result
end

function Public.rotate(positions, radians)
    local qx = cos(radians)
    local qy = sin(radians)

    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        local x, y = pos[1], pos[2]
        local rot_x = qx * x - qy * y
        local rot_y = qy * x + qx * y

        result[i] = {rot_x, rot_y}
    end

    return result
end

return Public
