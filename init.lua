local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local AscensionTags = EventDefs.AscensionTags
local EventTypes = EventDefs.Types

local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local _ = dofile_once("data/scripts/lib/coroutines.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("init.lua")

local eventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
local SpellDetector = dofile_once("mods/kaleva_koetus/files/scripts/spell_detector.lua")
local mark_enemy_as_processed

-- Select Difficulty
local difficultyManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
if ModSettingGet("kaleva_koetus.select_difficulty") == "beyond" then
  print("select difficulty manager")
  difficultyManager = dofile_once("mods/kaleva_koetus/files/scripts/beyond_manager.lua")
end

-- log:info("Kaleva Koetus mod loading...")

function OnModPreInit()
  -- log:debug("Mod - OnModPreInit()")
end

function OnModInit()
  -- log:debug("Mod - OnModInit()")
  -- Initialize Ascension System
  difficultyManager:init()
end

function OnModPostInit()
  -- log:debug("Mod - OnModPostInit()")

  difficultyManager:on_mod_post_init()
end

function OnWorldInitialized()
  eventBroker:init()
  EnemyDetector:init("from_init")
  SpellDetector:init("from_init")

  mark_enemy_as_processed = EnemyDetector:get_processed_marker()

  -- 存在するイベントをすべて登録する
  for _, event_type in pairs(EventTypes) do
    eventBroker:subscribe_event(event_type, difficultyManager)
  end

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  difficultyManager:on_world_initialized()

  -- Show current ascension info
  local info = difficultyManager:get_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Ascension " .. info.current .. " Active")
  end
end

function OnBiomeConfigLoaded()
  difficultyManager:on_biome_config_loaded()
end

function OnPlayerSpawned(player_entity_id) -- This runs when player entity has been created
  difficultyManager:on_player_spawn(player_entity_id)
end

function OnWorldPreUpdate()
  local unprocessed_enemies = EnemyDetector:check_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    eventBroker:direct_dispatch(EventTypes.ENEMY_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y, mark_enemy_as_processed)
  end

  unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    eventBroker:direct_dispatch(EventTypes.ENEMY_POST_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y)
  end

  local unprocessed_spells = SpellDetector:get_unprocessed_spells()
  for _, spell_data in ipairs(unprocessed_spells) do
    eventBroker:publish_event_sync("init", EventTypes.SPELL_GENERATED, spell_data.id)
  end

  eventBroker:flush_event_queue()

  -- NOTE:
  -- updateをEvent経由で呼ぶと大量に呼ばれてしまうので、直接callする
  difficultyManager:update()

  wake_up_waiting_threads(1)
end

function OnWorldPostUpdate() end

function OnMagicNumbersAndWorldSeedInitialized() end

-- append files
ModLuaFileAppend(
  "data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua",
  "mods/kaleva_koetus/files/scripts/appends/sampo_start_ending_sequence.lua"
)
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/boss_arena.lua")
ModLuaFileAppend("data/scripts/animals/necromancer_shop_spawn.lua", "mods/kaleva_koetus/files/scripts/appends/necromancer_shop_spawn.lua")
ModLuaFileAppend("data/scripts/items/potion.lua", "mods/kaleva_koetus/files/scripts/appends/potion.lua")
ModLuaFileAppend("data/scripts/items/potion_starting.lua", "mods/kaleva_koetus/files/scripts/appends/potion_starting.lua")
ModLuaFileAppend("data/scripts/game_helpers.lua", "mods/kaleva_koetus/files/scripts/appends/game_helpers.lua")

for content in nxml.edit_file("data/entities/items/books/base_book.xml") do
  content:create_child(
    "LuaComponent",
    { script_source_file = "mods/kaleva_koetus/files/scripts/appends/book.lua", execute_on_added = true, execute_every_n_frame = "-1" }
  )
end

for content in nxml.edit_file("data/entities/misc/sale_indicator.xml") do
  content:set("tags", AscensionTags.A2 .. "sale_indicator")
end

local translation_csv = ModTextFileGetContent("data/translations/common.csv")
local kaleva_koetus_translation_csv = ModTextFileGetContent("mods/kaleva_koetus/files/translations/common.csv")
ModTextFileSetContent("data/translations/common.csv", translation_csv .. kaleva_koetus_translation_csv)
