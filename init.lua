---@type Difficulty
local ascensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
if ascensionManager.init then
  ascensionManager:init()
end

function OnModPreInit()
  if ascensionManager.on_mod_pre_init then
    return ascensionManager:on_mod_pre_init()
  end
end

function OnModInit()
  if ascensionManager.on_mod_init then
    return ascensionManager:on_mod_init()
  end
end

function OnModPostInit()
  if ascensionManager.on_mod_post_init then
    return ascensionManager:on_mod_post_init()
  end
end

function OnBiomeConfigLoaded()
  if ascensionManager.on_biome_config_loaded then
    return ascensionManager:on_biome_config_loaded()
  end
end

function OnMagicNumbersAndWorldSeedInitialized()
  if ascensionManager.on_magic_numbers_and_world_seed_initialized then
    return ascensionManager:on_magic_numbers_and_world_seed_initialized()
  end
end

function OnWorldInitialized()
  if ascensionManager.on_world_initialized then
    return ascensionManager:on_world_initialized()
  end
end

function OnPlayerSpawned(player_entity)
  if ascensionManager.on_player_spawned then
    return ascensionManager:on_player_spawned(player_entity)
  end
end

function OnPlayerDied(player_entity)
  if ascensionManager.on_player_died then
    return ascensionManager:on_player_died(player_entity)
  end
end

function OnWorldPreUpdate()
  if ascensionManager.on_world_pre_update then
    return ascensionManager:on_world_pre_update()
  end
end

function OnWorldPostUpdate()
  if ascensionManager.on_world_post_update then
    return ascensionManager:on_world_post_update()
  end
end

function OnPausedChanged(is_paused, is_inventory_pause)
  if ascensionManager.on_paused_changed then
    return ascensionManager:on_paused_changed(is_paused, is_inventory_pause)
  end
end

function OnModSettingsChanged()
  if ascensionManager.on_mod_settings_changed then
    return ascensionManager:on_mod_settings_changed()
  end
end

function OnPausePreUpdate()
  if ascensionManager.on_pause_pre_update then
    return ascensionManager:on_pause_pre_update()
  end
end

function OnCountSecrets()
  if ascensionManager.on_count_secrets then
    return ascensionManager:on_count_secrets()
  else
    return 0, 0
  end
end
