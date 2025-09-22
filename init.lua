local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")

-- Load coroutine support for async processing
local _ = dofile_once("data/scripts/lib/coroutines.lua")

-- Load Ascension Manager
local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")

-- Load Event Observer
local EventObserver = dofile_once("mods/kaleva_koetus/files/scripts/observer/event_observer.lua")

-- Load Enemy Detector
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")

print("Kaleva Koetus mod loading...")

function OnModPreInit()
  print("Mod - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
  print("Mod - OnModInit()") -- After that this is called for all mods

  -- Initialize Ascension System
  AscensionManager:init()

  -- Note: EventObserver initialization moved to OnWorldInitialized due to Globals dependency
end

function OnModPostInit()
  print("Mod - OnModPostInit()") -- Then this is called for all mods
end

function OnPlayerSpawned(player_entity) -- This runs when player entity has been created
  -- Handle ascension on player spawn
  AscensionManager:on_player_spawn(player_entity)
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
  -- Initialize Event Observer (requires WorldState to exist)
  EventObserver:init()

  -- Initialize Enemy Detector
  EnemyDetector:init()

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  -- Show current ascension info
  local info = AscensionManager:get_ascension_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Ascension " .. info.current .. " Active")
  end
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
  -- Check for unprocessed enemies
  local unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()

  -- Publish events for unprocessed enemies
  if #unprocessed_enemies > 0 then
    local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
    local EventTypes = EventDefs.Types

    for _, enemy_data in ipairs(unprocessed_enemies) do
      EventObserver:publish_event_async("init", EventTypes.ENEMY_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y)
    end

    print("[Init] Published " .. #unprocessed_enemies .. " enemy spawn events")
  end

  -- Flush pending events via Observer
  EventObserver:flush_event_queue()

  -- NOTE:
  -- Update ascension system
  -- updateをEvent経由で呼ぶと大量に呼ばれてしまうので、直接callする
  AscensionManager:update()
end

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
  -- Post-update hook for debugging (commented out to reduce spam)
  -- GamePrint( "Post-update hook " .. tostring(GameGetFrameNum()) )
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
end

-- Append to sampo ending sequence for victory detection
ModLuaFileAppend(
  "data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua",
  "mods/kaleva_koetus/files/scripts/appends/sampo_start_ending_sequence.lua"
)

print("Kaleva Koetus mod loaded successfully!")
