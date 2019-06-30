local Event = require 'utils.event'

local generator_names = {
    ['basic-void-generator'] = true,
    ['advanced-void-generator'] = true,
    ['superior-void-generator'] = true
}

local function entity_built(event)
    local entity = event.created_entity
    if not entity or not entity.valid or not generator_names[entity.name] then
        return
    end

    entity.insert('void-fuel')
end

Event.add(defines.events.on_built_entity, entity_built)
Event.add(defines.events.on_robot_built_entity, entity_built)
