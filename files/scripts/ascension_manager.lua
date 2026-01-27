local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
local nxml_helper = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/nxml_helper.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local AscensionTags = EventDefs.Tags

---@type EventBroker
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
-- local SpellDetector = dofile_once("mods/kaleva_koetus/files/scripts/spell_detector.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local RNG = dofile_once("mods/kaleva_koetus/files/scripts/random_genarator.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("ascension_manager.lua")

local mark_enemy_as_processed

---@class AscensionManager : Difficulty
local AscensionManager = dofile("mods/kaleva_koetus/files/scripts/base_difficulty.lua")

function AscensionManager:init()
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
end

local function _load_ascension(level, max_level)
  if level < 1 or level > max_level then
    log:error("Invalid ascension level requested: %s", tostring(level))
    return nil
  end

  local path = "mods/kaleva_koetus/files/scripts/ascensions/a" .. level .. ".lua"
  local success, ascension = pcall(dofile, path)

  if success then
    -- log:debug("Loaded Ascension %d", level)
    return ascension
  else
    log:error("Failed to load Ascension %d: %s", level, tostring(ascension))
    return nil
  end
end

function AscensionManager:activate_ascension()
  -- log:info("Activating ascensions 1-%d", self.current_level)
  local max_level = self.get_max_level()
  self.active_ascensions = {}

  if self.single_ascension then
    local ascension = _load_ascension(self.current_level, max_level)
    if ascension then
      table.insert(self.active_ascensions, ascension)

      if ascension.on_mod_init then
        ascension:on_mod_init()
      end

      -- log:debug("Activated Ascension %d", self.current_level)
    end
  else
    for i = 1, self.current_level do
      local ascension = _load_ascension(i, max_level)
      if ascension then
        table.insert(self.active_ascensions, ascension)

        if ascension.on_mod_init then
          ascension:on_mod_init()
        end

        -- log:debug("Activated Ascension %d", i)
      end
    end

    if self.current_level > 0 then
      GamePrint("[Kaleva Koetus] Ascensions 1-" .. self.current_level .. " Active (" .. #self.active_ascensions .. " effects)")
    end
  end
end

function AscensionManager:on_mod_init()
  -- log:info("Initializing Ascension Manager")

  -- Load saved data
  self:load_progress()

  -- Activate ascension if current_level is set
  if self.current_level > 0 and self.current_level <= self.highest_level then
    self:activate_ascension()
    -- log:info("Start Ascension %d", self.current_level)
  else
    log:warn("No valid ascension to activate (current: %d, unlocked: %d)", self.current_level, self.highest_level)
  end

  if self.current_level >= 5 then
    ImageEditor:override_image("data/ui_gfx/inventory/background.png", "mods/kaleva_koetus/files/ui_gfx/inventory/a5_background.png")
  end
end

function AscensionManager:on_biome_config_loaded()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_biome_config_loaded then
      ascension:on_biome_config_loaded()
    end
  end
end

function AscensionManager:on_magic_numbers_and_world_seed_initialized()
  RNG.init_root_seed()
end

function AscensionManager:on_world_initialized()
  EnemyDetector:init("ascension")
  mark_enemy_as_processed = EnemyDetector:get_processed_marker()

  EventBroker:subscribe("ENEMY_SPAWN", function(...)
    return self:on_enemy_spawn(...)
  end)
  EventBroker:subscribe("ENEMY_POST_SPAWN", function(...)
    return self:on_enemy_post_spawn(...)
  end)
  EventBroker:subscribe("SHOP_CARD_SPAWN", function(...)
    return self:on_shop_card_spawn(...)
  end)
  EventBroker:subscribe("SHOP_WAND_SPAWN", function(...)
    return self:on_shop_wand_spawn(...)
  end)
  EventBroker:subscribe("VICTORY", function(...)
    return self:on_victory(...)
  end)
  EventBroker:subscribe("NECROMANCER_SPAWN", function(...)
    return self:on_necromancer_spawn(...)
  end)
  EventBroker:subscribe("POTION_GENERATED", function(...)
    return self:on_potion_generated(...)
  end)
  EventBroker:subscribe("BOOK_GENERATED", function(...)
    return self:on_book_generated(...)
  end)
  EventBroker:subscribe("GOLD_SPAWN", function(...)
    return self:on_gold_spawn(...)
  end)
  EventBroker:subscribe("SPELL_GENERATED", function(...)
    return self:on_spell_generated(...)
  end)
  EventBroker:subscribe("BOSS_DIED", function(...)
    return self:on_boss_died(...)
  end)
  EventBroker:subscribe("NEW_GAME_PLUS_STARTED", function(...)
    return self:on_new_game_plus_started(...)
  end)

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  -- Show current ascension info
  local info = self:get_ascension_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Ascension " .. info.current .. " Active")
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_world_initialized then
      ascension:on_world_initialized()
    end
  end
end

local function _add_ascension_info_perk(player_entity_id, current_level)
  local ascension_perk_added = GlobalsGetValue("kaleva_koetus_ascension_perk_added", "false") == "true"
  if not ascension_perk_added then
    -- 処理
    local entity_ui = EntityCreateNew("kaleva_koetus_ascension_info")

    local description = ""
    for i = 1, current_level, 1 do
      local line = GameTextGetTranslatedOrNot("$kaleva_koetus_specification_a" .. i) .. " [A" .. i .. "]" .. "\n"
      description = description .. line
    end

    local _ = EntityAddComponent2(entity_ui, "UIIconComponent", {
      name = "$kaleva_koetus_ascension_info_name",
      description = description,
      icon_sprite_file = "mods/kaleva_koetus/files/ui_gfx/ascensions/a" .. current_level .. ".png",
    })

    EntityAddChild(player_entity_id, entity_ui)

    GlobalsSetValue("kaleva_koetus_ascension_perk_added", "true")
  end
end

function AscensionManager:on_player_spawned(player_entity_id)
  local entity_id = tonumber(player_entity_id)
  if not entity_id then
    log:error("Invalid player entity id: %s", tostring(player_entity_id))
    return
  end

  log:info(#self.active_ascensions)
  log:info(self.active_ascensions[#self.active_ascensions])
  if self.current_level > 0 and self.active_ascensions[#self.active_ascensions].level == self.current_level then
    local translated_ascension = GameTextGetTranslatedOrNot("$kaleva_koetus_ascension")
    local translated_description = GameTextGetTranslatedOrNot(self.active_ascensions[#self.active_ascensions].description)
    GamePrintImportant(translated_ascension .. " " .. self.current_level, translated_description)
  end

  if ModSettingGet("kaleva_koetus.show_ascension_info") then
    _add_ascension_info_perk(player_entity_id, self.current_level)
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_player_spawned then
      ascension:on_player_spawned(entity_id)
    end
  end
end

function AscensionManager:on_world_pre_update()
  local unprocessed_enemies = EnemyDetector:check_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    EventBroker.direct.ENEMY_SPAWN(enemy_data.id, enemy_data.x, enemy_data.y, mark_enemy_as_processed)
  end

  unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    EventBroker.direct.ENEMY_POST_SPAWN(enemy_data.id, enemy_data.x, enemy_data.y)
  end

  EventBroker:flush_event_queue()

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_world_pre_update then
      ascension:on_world_pre_update()
    end
  end
end

function AscensionManager:on_enemy_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_enemy_spawn then
      ascension:on_enemy_spawn(...)
    end
  end
end

function AscensionManager:on_enemy_post_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_enemy_post_spawn then
      ascension:on_enemy_post_spawn(...)
    end
  end
end

function AscensionManager:on_shop_card_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_card_spawn then
      ascension:on_shop_card_spawn(...)
    end
  end
end

function AscensionManager:on_shop_wand_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_wand_spawn then
      ascension:on_shop_wand_spawn(...)
    end
  end
end

function AscensionManager:on_necromancer_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_necromancer_spawn then
      ascension:on_necromancer_spawn(...)
    end
  end
end

function AscensionManager:on_potion_generated(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_potion_generated then
      ascension:on_potion_generated(...)
    end
  end
end

function AscensionManager:on_book_generated(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_book_generated then
      ascension:on_book_generated(...)
    end
  end
end

function AscensionManager:on_gold_spawn(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_gold_spawn then
      ascension:on_gold_spawn(...)
    end
  end
end

function AscensionManager:on_spell_generated(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_spell_generated then
      ascension:on_spell_generated(...)
    end
  end
end

function AscensionManager:on_mod_post_init(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_mod_post_init then
      ascension:on_mod_post_init(...)
    end
  end
end

function AscensionManager:on_boss_died(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_boss_died then
      ascension:on_boss_died(...)
    end
  end
end

function AscensionManager:on_new_game_plus_started(...)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_new_game_plus_started then
      ascension:on_new_game_plus_started(...)
    end
  end
end

function AscensionManager:on_victory(...)
  -- log:info("Victory detected at level %d (highest unlocked %d)", self.current_level, self.highest_level)
  local current_ascension = self.active_ascensions[#self.active_ascensions]
  if current_ascension and current_ascension.should_unlock_next and current_ascension:should_unlock_next() then
    if self.current_level == 0 then
      log:warn("Victory with no ascension active (current level 0)")
      GamePrintImportant("Victory! (No ascension active)")
    elseif self:can_unlock_next_level() then
      self.highest_level = self.highest_level + 1
      -- log:info("Ascension %d cleared. Unlocking %d", self.current_level, self.highest_level)
      GamePrintImportant("Ascension " .. self.current_level .. " Cleared! ", "Ascension " .. self.highest_level .. " Unlocked!")
      self.current_level = self.current_level + 1
    else
      -- log:info("Ascension %d cleared", self.current_level)
      GamePrintImportant("Ascension " .. self.current_level .. " Cleared! ")
    end
  end
  self:save_progress()

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_victory then
      ascension:on_victory(...)
    end
  end
end

return AscensionManager
