local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local _ = dofile_once("data/scripts/lib/coroutines.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("init.lua")

local ascensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
local eventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
local SpellDetector = dofile_once("mods/kaleva_koetus/files/scripts/spell_detector.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

log:info("Kaleva Koetus mod loading...")

function OnModPreInit()
  log:debug("Mod - OnModPreInit()")
end

function OnModInit()
  log:debug("Mod - OnModInit()")
  -- Initialize Ascension System
  ascensionManager:init()
  if ascensionManager.current_level >= 5 then
    ImageEditor:override_image("data/ui_gfx/inventory/background.png", "mods/kaleva_koetus/files/ui_gfx/inventory/a5_background.png")
  end
end

function OnModPostInit()
  log:debug("Mod - OnModPostInit()")

  ascensionManager:on_mod_post_init()
end

function OnWorldInitialized()
  eventBroker:init()
  EnemyDetector:init("from_init")
  SpellDetector:init("from_init")

  -- 存在するイベントをすべて登録する
  for _, event_type in pairs(EventTypes) do
    eventBroker:subscribe_event(event_type, ascensionManager)
  end

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  ascensionManager:on_world_initialized()

  -- Show current ascension info
  local info = ascensionManager:get_ascension_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Ascension " .. info.current .. " Active")
  end
end

function OnPlayerSpawned(player_entity_id) -- This runs when player entity has been created
  ascensionManager:on_player_spawn(player_entity_id)
end

function OnWorldPreUpdate()
  local unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()
  if #unprocessed_enemies > 0 then
    for _, enemy_data in ipairs(unprocessed_enemies) do
      eventBroker:publish_event_sync("init", EventTypes.ENEMY_SPAWN, enemy_data.id, enemy_data.x, enemy_data.y)
    end
  end

  local unprocessed_spells = SpellDetector:get_unprocessed_spells()
  if #unprocessed_spells > 0 then
    for _, spell_data in ipairs(unprocessed_spells) do
      eventBroker:publish_event_sync("init", EventTypes.SPELL_GENERATED, spell_data.id)
    end
  end

  eventBroker:flush_event_queue()

  -- NOTE:
  -- updateをEvent経由で呼ぶと大量に呼ばれてしまうので、直接callする
  ascensionManager:update()

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
ModLuaFileAppend("data/scripts/magic/fungal_shift.lua", "mods/kaleva_koetus/files/scripts/appends/fungal_shift.lua")
ModLuaFileAppend("data/scripts/status_effects/status_list.lua", "mods/kaleva_koetus/files/scripts/appends/status_list.lua")
ModLuaFileAppend("data/scripts/game_helpers.lua", "mods/kaleva_koetus/files/scripts/appends/game_helpers.lua")

for content in nxml.edit_file("data/entities/items/books/base_book.xml") do
  content:create_child("LuaComponent", { script_source_file = "mods/kaleva_koetus/files/scripts/appends/book.lua" })
end

for content in nxml.edit_file("data/entities/misc/sale_indicator.xml") do
  content:set("tags", AscensionTags.A2 .. "sale_indicator")
end

local translation_csv = ModTextFileGetContent("data/translations/common.csv")
local kaleva_koetus_translation_csv = ModTextFileGetContent("mods/kaleva_koetus/files/translations/common.csv")
ModTextFileSetContent("data/translations/common.csv", translation_csv .. kaleva_koetus_translation_csv)
