local Event = require 'utils.event'

Event.on_init(
    function()
        local recipes = game.forces.player.recipes
        recipes['steam-engine'].enabled = false
        recipes['burner-mining-drill'].enabled = false
        recipes['electric-mining-drill'].enabled = false
        recipes['automation-science-pack'].enabled = false
        recipes['electronic-circuit'].enabled = false
        recipes['inserter'].enabled = false
        recipes['transport-belt'].enabled = false
        recipes['pipe'].enabled = false

        local technologies = game.forces.player.technologies
        technologies['basic-metal-mining'].researched = true
        technologies['basic-science-pack'].researched = true
        technologies['basic-void-generator'].researched = true
    end
)
