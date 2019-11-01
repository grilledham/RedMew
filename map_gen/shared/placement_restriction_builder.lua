local Popup = require 'features.gui.popup'
local Event = require 'utils.event'
local LocaleBuilder = require 'utils.locale_builder'

local Public = {}

-- Helpers

local function array_to_set(tbl)
    for i = 1, #tbl do
        local key = tbl[i]
        tbl[key] = true
    end
end

-- Rule sets

function Public.banned_entities(entities)
    if type(entities) ~= 'table' then
        error('entities must be a table', 2)
    end

    array_to_set(entities)

    return function(data)
        return not entities[data.entity_name]
    end
end

function Public.allowed_entities(entities)
    if type(entities) ~= 'table' then
        error('entities must be a table', 2)
    end

    array_to_set(entities)

    return function(data)
        return entities[data.entity_name]
    end
end

function Public.ban_entities_on_resources()
    local filter = {type = 'resource', limit = 1}
    return function(data)
        local entity = data.entity

        -- Some entities have a bounding_box area of zero, eg robots.
        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
            return true
        end

        filter.area = area
        local count = entity.surface.count_entities_filtered(filter)
        return count == 0
    end
end

-- Combinators

function Public.invert(rule)
    return function(data)
        return not rule(data)
    end
end

function Public.all(rules)
    if type(rules) ~= 'table' or (#rules == 0) then
        error('rules must be a non empty array table', 2)
    end

    local count = #rules

    return function(data)
        for i = 1, count do
            if not rules[i](data) then
                return false
            end
        end

        return true
    end
end

function Public.any(rules)
    if type(rules) ~= 'table' or (#rules == 0) then
        error('rules must be a non empty array table', 2)
    end

    local count = #rules

    return function(data)
        for i = 1, count do
            if rules[i](data) then
                return true
            end
        end

        return false
    end
end

-- Pre rule hooks

function Public.include_ghosts(rule)
    return function(data)
        local name = data.entity_name

        if name == 'entity-ghost' then
            data.ghost = true
            data.entity_name = data.entity.ghost_name
        end

        return rule(data)
    end
end

-- Post rule hooks

function Public.destroy_entity(rule)
    return function(data)
        local allowed = rule(data)

        if not allowed then
            data.entity.destroy()
        end

        return allowed
    end
end

function Public.refund_item(rule)
    return function(data)
        local allowed = rule(data)

        if not allowed and not data.ghost then
            local item = data.item
            if item and item.valid then
                data.player.insert {name = item.name, amount = 1}
            end
        end

        return allowed
    end
end

function Public.popup(rule, message, title, sprite_path, popup_name)
    return function(data)
        local allowed = rule(data)

        if not allowed then
            Popup.player(data.player, message, title, sprite_path, popup_name)
        end

        return allowed
    end
end

function Public.entity_popup(rule, optional_custom_message)
    if optional_custom_message then
        optional_custom_message = ' ' .. optional_custom_message
    else
        optional_custom_message = ' is banned and cannot be placed.'
    end

    return function(data)
        local allowed = rule(data)

        if not allowed then
            local name = data.entity_name
            local message = table.concat({'Entity: [entity=', name, '] ', name, optional_custom_message})
            Popup.player(data.player, message, 'Banned entity', nil, 'placement_restriction_builder')
        end

        return allowed
    end
end

-- Event handlers

function Public.handler_for_on_built_entity(rule)
    return function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        event.entity = entity
        event.entity_name = entity.name
        event.player = player

        return rule(event)
    end
end

function Public.register_on_built_entity(rule)
    Event.add(defines.events.on_built_entity, Public.handler_for_on_built_entity(rule))
end

return Public
