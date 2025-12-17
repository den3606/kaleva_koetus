local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
local nxml_helper = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/nxml_helper.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local _ = dofile_once("data/scripts/lib/coroutines.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("init.lua")

local ascensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
local eventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
-- local SpellDetector = dofile_once("mods/kaleva_koetus/files/scripts/spell_detector.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local RNG = dofile_once("mods/kaleva_koetus/files/scripts/random_genarator.lua")

local mark_enemy_as_processed
-- log:info("Kaleva Koetus mod loading...")

function OnModPreInit()
  -- log:debug("Mod - OnModPreInit()")
end

function OnModInit()
  -- log:debug("Mod - OnModInit()")
  -- Initialize Ascension System
  ascensionManager:init()
  if ascensionManager.current_level >= 5 then
    ImageEditor:override_image("data/ui_gfx/inventory/background.png", "mods/kaleva_koetus/files/ui_gfx/inventory/a5_background.png")
  end
end

function OnModPostInit()
  -- log:debug("Mod - OnModPostInit()")

  ascensionManager:on_mod_post_init()
end

function OnMagicNumbersAndWorldSeedInitialized()
  RNG.init_root_seed()
end

function OnWorldInitialized()
  eventBroker:init()
  EnemyDetector:init("from_init")
  -- SpellDetector:init("from_init")

  mark_enemy_as_processed = EnemyDetector:get_processed_marker()

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

function OnBiomeConfigLoaded()
  ascensionManager:on_biome_config_loaded()
end

function OnPlayerSpawned(player_entity_id) -- This runs when player entity has been created
  ascensionManager:on_player_spawn(player_entity_id)
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

  -- local unprocessed_spells = SpellDetector:get_unprocessed_spells()
  -- for _, spell_data in ipairs(unprocessed_spells) do
  --   eventBroker:publish_event_sync("init", EventTypes.SPELL_GENERATED, spell_data.id)
  -- end

  eventBroker:flush_event_queue()

  -- NOTE:
  -- updateをEvent経由で呼ぶと大量に呼ばれてしまうので、直接callする
  ascensionManager:update()

  wake_up_waiting_threads(1)
end

function OnWorldPostUpdate() end

-- append files
ModLuaFileAppend(
  "data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua",
  "mods/kaleva_koetus/files/scripts/appends/sampo_start_ending_sequence.lua"
)
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/kaleva_koetus/files/scripts/appends/temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/boss_arena.lua")
ModLuaFileAppend("data/scripts/animals/necromancer_shop_spawn.lua", "mods/kaleva_koetus/files/scripts/appends/necromancer_shop_spawn.lua")
ModLuaFileAppend("data/scripts/perks/gold_explosion.lua", "mods/kaleva_koetus/files/scripts/appends/gold_explosion.lua")

local error_tracker = nxml_helper.create_tracker_ignoring({ "duplicate_attribute" })
nxml_helper.use_error_handler(nxml, error_tracker.error_handler, function()
  local potions_to_edit = {
    "data/entities/items/pickup/potion.xml",
    "data/entities/items/easter/beer_bottle.xml",
  }
  for _, potion_file in ipairs(potions_to_edit) do
    for content in nxml.edit_file(potion_file) do
      content:create_child("LuaComponent", {
        script_source_file = "mods/kaleva_koetus/files/scripts/appends/potion_spawn.lua",
        execute_on_added = "1",
        execute_every_n_frame = "-1",
        remove_after_executed = "1",
      })
    end
  end

  for content in nxml.edit_file("data/entities/items/pickup/potion_aggressive.xml") do
    content:create_child("LuaComponent", {
      execute_every_n_frame = "-1",
      remove_after_executed = "1",
      script_item_picked_up = "mods/kaleva_koetus/files/scripts/appends/potion_aggressive_pick_up.lua",
    })

    local base = content:first_of("Base")
    if base then
      base:create_child("LuaComponent", { _remove_from_base = "1" })
    end
  end

  for content in nxml.edit_file("data/entities/items/books/base_book.xml") do
    content:create_child(
      "LuaComponent",
      { script_source_file = "mods/kaleva_koetus/files/scripts/appends/book.lua", execute_on_added = true, execute_every_n_frame = "-1" }
    )
  end

  for content in nxml.edit_file("data/entities/misc/sale_indicator.xml") do
    content:set("tags", AscensionTags.A2 .. "sale_indicator")
  end
end)

local translation_csv = ModTextFileGetContent("data/translations/common.csv")
local kaleva_koetus_translation_csv = ModTextFileGetContent("mods/kaleva_koetus/files/translations/common.csv")
ModTextFileSetContent("data/translations/common.csv", translation_csv .. kaleva_koetus_translation_csv)
