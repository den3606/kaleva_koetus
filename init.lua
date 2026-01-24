local function check_function(f)
  return f and type(f) == "function"
end

local ascensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
if check_function(ascensionManager.init) then
  ascensionManager:init()
end

function OnModPreInit()
  if check_function(ascensionManager.on_mod_pre_init) then
    ascensionManager:on_mod_pre_init()
  end
end

function OnModInit()
  if check_function(ascensionManager.on_mod_init) then
    ascensionManager:on_mod_init()
  end
end

function OnModPostInit()
  if check_function(ascensionManager.on_mod_post_init) then
    ascensionManager:on_mod_post_init()
  end
end

function OnBiomeConfigLoaded()
  if check_function(ascensionManager.on_biome_config_loaded) then
    ascensionManager:on_biome_config_loaded()
  end
end

function OnMagicNumbersAndWorldSeedInitialized()
  if check_function(ascensionManager.on_magic_numbers_and_world_seed_initialized) then
    ascensionManager:on_magic_numbers_and_world_seed_initialized()
  end
end

function OnWorldInitialized()
  if check_function(ascensionManager.on_world_initialized) then
    ascensionManager:on_world_initialized()
  end
end

function OnPlayerSpawned(player_entity)
  if check_function(ascensionManager.on_player_spawn) then
    ascensionManager:on_player_spawn(player_entity)
  end
end

function OnWorldPreUpdate()
  if check_function(ascensionManager.on_world_pre_update) then
    ascensionManager:on_world_pre_update()
  end
end

function OnWorldPostUpdate()
  if check_function(ascensionManager.on_world_post_update) then
    ascensionManager:on_world_post_update()
  end
end
