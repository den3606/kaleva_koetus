dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")

-- Load coroutine support for async processing
dofile_once("data/scripts/lib/coroutines.lua")

-- Load Ascension Manager
local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")

-- Load Victory Handler
local VictoryHandler = dofile_once("mods/kaleva_koetus/files/scripts/victory_handler.lua")

-- Load Event Observer
local EventObserver = dofile_once("mods/kaleva_koetus/files/scripts/event_observer.lua")

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
      EventObserver:publish_event("init", EventTypes.ENEMY_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y)
    end

    print("[Init] Published " .. #unprocessed_enemies .. " enemy spawn events")
  end

  -- Process events via Observer
  EventObserver:process_events()

  -- Update ascension system
  AscensionManager:update()

  -- Check for victory every 60 frames (1 second)
  if GameGetFrameNum() % 60 == 0 then
    if VictoryHandler and VictoryHandler:check_victory() then
      VictoryHandler:on_victory()
    end
  end
end

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
  -- Post-update hook for debugging (commented out to reduce spam)
  -- GamePrint( "Post-update hook " .. tostring(GameGetFrameNum()) )
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
end

ModLuaFileAppend("data/scripts/director_helpers.lua", "mods/kaleva_koetus/files/scripts/appends/director_helpers.lua")

print("Kaleva Koetus mod loaded successfully!")
