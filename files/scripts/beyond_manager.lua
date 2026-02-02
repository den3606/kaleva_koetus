local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
local nxml_helper = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/nxml_helper.lua")

---@type Events
local Events = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/events.lua")
local EnemyDetector = dofile_once("mods/kaleva_koetus/files/scripts/enemy_detector.lua")
local RNG = dofile_once("mods/kaleva_koetus/files/scripts/random_genarator.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("beyond_manager.lua")

local mark_enemy_as_processed

---@type DifficultyManager
local DifficultyManager = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_manager.lua")

---@class BeyondManager : Difficulty
---@field active_levels Beyond[]
local BeyondManager = DifficultyManager.create("beyond")

function BeyondManager:init()
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
  end)

  local translation_csv = ModTextFileGetContent("data/translations/common.csv")
  local kaleva_koetus_translation_csv = ModTextFileGetContent("mods/kaleva_koetus/files/translations/common.csv")
  ModTextFileSetContent("data/translations/common.csv", translation_csv .. kaleva_koetus_translation_csv)
end

local function _load_beyond(level, max_level)
  if level < 1 or level > max_level then
    log:warn("Invalid beyond level requested: %s", tostring(level))
    return nil
  end

  local path = "mods/kaleva_koetus/files/scripts/beyonds/b" .. level .. ".lua"
  local success, beyond = pcall(dofile, path)

  if success then
    -- log:debug("Loaded Beyond %d", level)
    return beyond
  else
    log:warn("Failed to load Beyond %d: %s", level, tostring(beyond))
    return nil
  end
end

function BeyondManager:activate_beyond()
  -- log:info("Activating beyonds 1-%d", self.current_level)
  local max_level = self.get_max_level()
  self.active_levels = {}

  if self.single_level then
    local beyond = _load_beyond(self.current_level, max_level)
    if beyond then
      table.insert(self.active_levels, beyond)

      -- log:debug("Activated Beyond %d", self.current_level)
    end
  else
    for i = 1, self.current_level do
      local beyond = _load_beyond(i, max_level)
      if beyond then
        table.insert(self.active_levels, beyond)

        -- log:debug("Activated Beyond %d", i)
      end
    end

    if self.current_level > 0 then
      GamePrint("[Kaleva Koetus] Beyonds 1-" .. self.current_level .. " Active (" .. #self.active_levels .. " effects)")
    end
  end
end

function BeyondManager:on_mod_init()
  -- Load saved data
  self:load_progress()
  self:activate_beyond()

  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_mod_init then
      beyond:on_mod_init()
    end
  end
end

function BeyondManager:on_mod_post_init()
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_mod_post_init then
      beyond:on_mod_post_init()
    end
  end
end

function BeyondManager:on_biome_config_loaded()
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_biome_config_loaded then
      beyond:on_biome_config_loaded()
    end
  end
end

function BeyondManager:on_magic_numbers_and_world_seed_initialized()
  RNG.init_root_seed()
end

function BeyondManager:on_world_initialized()
  EnemyDetector:init("beyond")
  mark_enemy_as_processed = EnemyDetector:get_processed_marker()

  function Events.on.BOOK_GENERATED(...)
    return self:on_book_generated(...)
  end
  function Events.on.BOSS_DIED()
    return self:on_boss_died()
  end
  function Events.on.ENEMY_POST_SPAWN(...)
    return self:on_enemy_post_spawn(...)
  end
  function Events.on.ENEMY_SPAWN(...)
    return self:on_enemy_spawn(...)
  end
  function Events.on.GOLD_SPAWN(...)
    return self:on_gold_spawn(...)
  end
  function Events.on.NECROMANCER_SPAWN(...)
    return self:on_necromancer_spawn(...)
  end
  function Events.on.NEW_GAME_PLUS_STARTED()
    return self:on_new_game_plus_started()
  end
  function Events.on.POTION_GENERATED(...)
    return self:on_potion_generated(...)
  end
  function Events.on.SHOP_CARD_SPAWN(...)
    return self:on_shop_card_spawn(...)
  end
  function Events.on.SHOP_WAND_SPAWN(...)
    return self:on_shop_wand_spawn(...)
  end
  function Events.on.VICTORY()
    return self:on_victory()
  end

  -- Reset victory flag for new run
  GlobalsSetValue("kaleva_koetus_victory_processed", "0")

  -- Show current beyond info
  local info = self:get_info()
  if info.current > 0 then
    GamePrint("[Kaleva Koetus] Beyond " .. info.current .. " Active")
  end

  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_world_initialized then
      beyond:on_world_initialized()
    end
  end
end

local function _add_beyond_info_perk(player_entity_id, current_level)
  local beyond_perk_added = GlobalsGetValue("kaleva_koetus_beyond_perk_added", "false") == "true"
  if not beyond_perk_added then
    -- 処理
    local entity_ui = EntityCreateNew("kaleva_koetus_beyond_info")

    local description = ""
    for i = 1, current_level, 1 do
      local line = GameTextGetTranslatedOrNot("$kaleva_koetus_specification_b" .. i) .. " [B" .. i .. "]" .. "\n"
      description = description .. line
    end

    local _ = EntityAddComponent2(entity_ui, "UIIconComponent", {
      name = "$kaleva_koetus_beyond_info_name",
      description = description,
      icon_sprite_file = "mods/kaleva_koetus/files/ui_gfx/beyonds/b" .. current_level .. ".png",
    })

    EntityAddChild(player_entity_id, entity_ui)

    GlobalsSetValue("kaleva_koetus_beyond_perk_added", "true")
  end
end

function BeyondManager:on_player_spawned(player_entity_id)
  log:info(#self.active_levels)
  log:info(self.active_levels[#self.active_levels])
  if self.current_level > 0 and self.active_levels[#self.active_levels].level == self.current_level then
    local translated_beyond = GameTextGetTranslatedOrNot("$kaleva_koetus_beyond")
    local translated_description = GameTextGetTranslatedOrNot(self.active_levels[#self.active_levels].description)
    GamePrintImportant(translated_beyond .. " " .. self.current_level, translated_description)
  end

  if self:should_show_info() then
    _add_beyond_info_perk(player_entity_id, self.current_level)
  end

  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_player_spawned then
      beyond:on_player_spawned(player_entity_id)
    end
  end
end

function BeyondManager:on_world_pre_update()
  local unprocessed_enemies = EnemyDetector:check_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    Events.direct.ENEMY_SPAWN(enemy_data.id, enemy_data.x, enemy_data.y, mark_enemy_as_processed)
  end

  unprocessed_enemies = EnemyDetector:get_unprocessed_enemies()
  for _, enemy_data in ipairs(unprocessed_enemies) do
    Events.direct.ENEMY_POST_SPAWN(enemy_data.id, enemy_data.x, enemy_data.y)
  end

  Events.flush_queue()

  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_world_pre_update then
      beyond:on_world_pre_update()
    end
  end
end

function BeyondManager:on_book_generated(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_book_generated then
      beyond:on_book_generated(...)
    end
  end
end

function BeyondManager:on_boss_died()
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_boss_died then
      beyond:on_boss_died()
    end
  end
end

function BeyondManager:on_enemy_post_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_enemy_post_spawn then
      beyond:on_enemy_post_spawn(...)
    end
  end
end

function BeyondManager:on_enemy_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_enemy_spawn then
      beyond:on_enemy_spawn(...)
    end
  end
end

function BeyondManager:on_gold_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_gold_spawn then
      beyond:on_gold_spawn(...)
    end
  end
end

function BeyondManager:on_necromancer_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_necromancer_spawn then
      beyond:on_necromancer_spawn(...)
    end
  end
end

function BeyondManager:on_new_game_plus_started()
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_new_game_plus_started then
      beyond:on_new_game_plus_started()
    end
  end
end

function BeyondManager:on_potion_generated(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_potion_generated then
      beyond:on_potion_generated(...)
    end
  end
end

function BeyondManager:on_shop_card_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_shop_card_spawn then
      beyond:on_shop_card_spawn(...)
    end
  end
end

function BeyondManager:on_shop_wand_spawn(...)
  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_shop_wand_spawn then
      beyond:on_shop_wand_spawn(...)
    end
  end
end

function BeyondManager:on_victory()
  -- log:info("Victory detected at level %d (highest unlocked %d)", self.current_level, self.highest_level)
  if self.current_level == 0 then
    log:warn("Victory with no beyond active (current level 0)")
    GamePrintImportant("Victory! (No beyond active)")
  elseif self:will_unlock_next_level() then
    GamePrintImportant("Beyond " .. self.current_level .. " Cleared! ", "Beyond " .. (self.highest_level + 1) .. " Unlocked!")
  elseif self:will_unlock_next_difficulty() then
    GamePrintImportant("Beyond " .. self.current_level .. " Cleared! ", "??? levels Unlocked!")
  end

  self:update_progress()

  for _, beyond in ipairs(self.active_levels) do
    if beyond.on_victory then
      beyond:on_victory()
    end
  end
end

return BeyondManager
