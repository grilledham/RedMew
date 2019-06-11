local Public = {}
Public.__index = Public

local setmetatable = setmetatable
local cos = math.cos
local sin = math.sin

Public.identity =
    setmetatable(
    {
        {1, 0, 0},
        {0, 1, 0}
    },
    Public
)

function Public.multiply(left, right)
    local left1, right1 = left[1], right[1]
    local left2, right2 = left[2], right[2]

    local l11, l12, l13 = left1[1], left1[2], left1[3]
    local l21, l22, l23 = left2[1], left2[2], left2[3]
    local r11, r12 = right1[1], right1[2]
    local r21, r22 = right2[1], right2[2]

    local a11 = r11 * l11 + r12 * l21
    local a12 = r11 * l12 + r12 * l22
    local a13 = r11 * l13 + r12 * l23 + right1[3]
    local a21 = r21 * l11 + r22 * l21
    local a22 = r21 * l12 + r22 * l22
    local a23 = r21 * l13 + r22 * l23 + right2[3]

    return setmetatable({{a11, a12, a13}, {a21, a22, a23}}, Public)
end
Public.__mul = Public.multiply

function Public.translation(x, y)
    return setmetatable(
        {
            {1, 0, x},
            {0, 1, y}
        },
        Public
    )
end

function Public.scale(x, y)
    return setmetatable(
        {
            {x, 0, 0},
            {0, y, 0}
        },
        Public
    )
end

function Public.rotation(radians)
    local qx = cos(radians)
    local qy = sin(radians)

    return setmetatable(
        {
            {qx, -qy, 0},
            {qy, qx, 0}
        },
        Public
    )
end

function Public.transform(radians, scale_x, scale_y, x, y)
    local qx = cos(radians)
    local qy = sin(radians)

    return setmetatable(
        {
            {scale_x * qx, -qy, x},
            {qy, scale_y * qx, y}
        },
        Public
    )
end

function Public.transform_position(matrix, position)
    local pos_x, pos_y = position[1], position[2]

    local row1 = matrix[1]
    local row2 = matrix[2]

    local x = row1[1] * pos_x + row1[2] * pos_y + row1[3]
    local y = row2[1] * pos_x + row2[2] * pos_y + row2[3]

    return {x, y}
end
local transform_position = transform_position

function Public.transform_positions(matrix, positions)
    local result = {}

    local row1 = matrix[1]
    local row2 = matrix[2]

    for i = 1, #positions do
        position = positions[i]
        local pos_x, pos_y = position[1], position[2]

        local x = row1[1] * pos_x + row1[2] * pos_y + row1[3]
        local y = row2[1] * pos_x + row2[2] * pos_y + row2[3]

        result[i] = {x, y}
    end

    return result
end

return Public
