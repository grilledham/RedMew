local Config = global.config

if Config then
    Config.autofill.enabled = false
    Config.market.enabled = false
    Config.reactor_meltdown.enabled = false
    Config.hail_hydra.enabled = false
    Config.player_rewards.enabled = false
    Config.autodeconstruct.enabled = false
    Config.turret_active_delay.enabled = false
    Config.player_create.starting_items = {}
end
