local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("init.lua")

---@type DifficultyManager
local DifficultyManager = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_manager.lua")
local current_difficulty = DifficultyManager.get_current_difficulty()

local difficulty

if current_difficulty == "ascension" then
  ---@type Difficulty
  difficulty = dofile("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
elseif current_difficulty == "beyond" then
  ---@type Difficulty
  difficulty = dofile("mods/kaleva_koetus/files/scripts/beyond_manager.lua")
else
  log:error("%s is not implemented yet.", current_difficulty)
  return
end

if difficulty.init then
  difficulty:init()
end

function OnModPreInit()
  if difficulty.on_mod_pre_init then
    return difficulty:on_mod_pre_init()
  end
end

function OnModInit()
  if difficulty.on_mod_init then
    return difficulty:on_mod_init()
  end
end

function OnModPostInit()
  if difficulty.on_mod_post_init then
    return difficulty:on_mod_post_init()
  end
end

function OnBiomeConfigLoaded()
  if difficulty.on_biome_config_loaded then
    return difficulty:on_biome_config_loaded()
  end
end

function OnMagicNumbersAndWorldSeedInitialized()
  if difficulty.on_magic_numbers_and_world_seed_initialized then
    return difficulty:on_magic_numbers_and_world_seed_initialized()
  end
end

function OnWorldInitialized()
  if difficulty.on_world_initialized then
    return difficulty:on_world_initialized()
  end
end

function OnPlayerSpawned(player_entity)
  if difficulty.on_player_spawned then
    return difficulty:on_player_spawned(player_entity)
  end
end

function OnPlayerDied(player_entity)
  if difficulty.on_player_died then
    return difficulty:on_player_died(player_entity)
  end
end

function OnWorldPreUpdate()
  if difficulty.on_world_pre_update then
    return difficulty:on_world_pre_update()
  end
end

function OnWorldPostUpdate()
  if difficulty.on_world_post_update then
    return difficulty:on_world_post_update()
  end
end

function OnPausedChanged(is_paused, is_inventory_pause)
  if difficulty.on_paused_changed then
    return difficulty:on_paused_changed(is_paused, is_inventory_pause)
  end
end

function OnModSettingsChanged()
  if difficulty.on_mod_settings_changed then
    return difficulty:on_mod_settings_changed()
  end
end

function OnPausePreUpdate()
  if difficulty.on_pause_pre_update then
    return difficulty:on_pause_pre_update()
  end
end

function OnCountSecrets()
  if difficulty.on_count_secrets then
    return difficulty:on_count_secrets()
  else
    return 0, 0
  end
end
