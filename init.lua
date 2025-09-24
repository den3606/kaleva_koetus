local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types

local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local _ = dofile_once("data/scripts/lib/coroutines.lua")

local ascensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
local eventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

print("Kaleva Koetus mod loading...")

function OnModPreInit()
  print("Mod - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
  print("Mod - OnModInit()") -- After that this is called for all mods
end

function OnModPostInit()
  print("Mod - OnModPostInit()") -- Then this is called for all mods
  -- Initialize Ascension System
  ascensionManager:init()
  if ascensionManager.current_level >= 5 then
    ImageEditor:override_image("data/ui_gfx/inventory/background.png", "mods/kaleva_koetus/files/overrides/a5_background.png")
  end

  print("Kaleva Koetus mod loaded successfully!")
end

function OnPlayerSpawned(player_entity_id) -- This runs when player entity has been created
  ascensionManager:on_player_spawn(player_entity_id)
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
  eventBroker:init()
  EnemyDetector:init()

  -- 存在するイベントをすべて登録する
  for _, event_type in pairs(EventTypes) do
    eventBroker:subscribe_event(event_type, ascensionManager)
  end

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  -- Show current ascension info
  local info = ascensionManager:get_ascension_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Ascension " .. info.current .. " Active")
  end
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
  -- Check for unprocessed enemies
  local unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()

  -- Publish events for unprocessed enemies
  if #unprocessed_enemies > 0 then
    for _, enemy_data in ipairs(unprocessed_enemies) do
      eventBroker:publish_event_sync("init", EventTypes.ENEMY_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y)
    end
  end

  eventBroker:flush_event_queue()

  -- NOTE:
  -- updateをEvent経由で呼ぶと大量に呼ばれてしまぁE�Eで、直接callする
  ascensionManager:update()
end

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
end

-- Append to sampo ending sequence for victory detection
ModLuaFileAppend(
  "data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua",
  "mods/kaleva_koetus/files/scripts/appends/sampo_start_ending_sequence.lua"
)
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/kaleva_koetus/files/scripts/appends/temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/boss_arena.lua")
ModLuaFileAppend("data/scripts/animals/necromancer_shop_spawn.lua", "mods/kaleva_koetus/files/scripts/appends/necromancer_shop_spawn.lua")
