local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("beyond_manager.lua")

local BeyondManager = {}

BeyondManager.MAX_LEVEL = 20

-- State
BeyondManager.current_level = 1
BeyondManager.highest_level = 1
BeyondManager.single_beyond = false
BeyondManager.active_beyonds = {}

function BeyondManager:init()
  -- log:info("Initializing Beyond Manager")

  -- Load saved data
  self:load_progress()

  -- Activate beyond if current_level is set
  if self.current_level > 0 and self.current_level <= self.highest_level then
    self:activate_beyond(self.current_level)
    -- log:info("Start Beyond %d", self.current_level)
  else
    log:warn("No valid beyond to activate (current: %d, unlocked: %d)", self.current_level, self.highest_level)
  end
end

function BeyondManager:_load_beyond(level)
  if level < 1 or level > self.MAX_LEVEL then
    log:error("Invalid beyond level requested: %s", tostring(level))
    return nil
  end

  local path = "mods/kaleva_koetus/files/scripts/beyonds/b" .. level .. ".lua"
  local success, beyond = pcall(dofile, path)

  if success then
    -- log:debug("Loaded Beyond %d", level)
    return beyond
  else
    log:error("Failed to load Beyond %d: %s", level, tostring(beyond))
    return nil
  end
end

function BeyondManager:activate_beyond()
  -- log:info("Activating beyonds 1-%d", self.current_level)

  self.active_beyonds = {}

  if self.single_beyond then
    local beyond = self:_load_beyond(self.current_level)
    if beyond then
      table.insert(self.active_beyonds, beyond)

      if beyond.on_activate then
        beyond:on_activate()
      end

      -- log:debug("Activated Beyond %d", self.current_level)
    end
  else
    for i = 1, self.current_level do
      local beyond = self:_load_beyond(i)
      if beyond then
        table.insert(self.active_beyonds, beyond)

        if beyond.on_activate then
          beyond:on_activate()
        end

        -- log:debug("Activated Beyond %d", i)
      end
    end

    if self.current_level > 0 then
      GamePrint("[Kaleva Koetus] Beyonds 1-" .. self.current_level .. " Active (" .. #self.active_beyonds .. " effects)")
    end
  end
end

function BeyondManager:load_progress()
  self.highest_level = tonumber(ModSettingGet("kaleva_koetus.beyond_highest") or "1")
  self.current_level = tonumber(ModSettingGet("kaleva_koetus.beyond_current") or "1")

  self.single_beyond = ModSettingGet("kaleva_koetus.single_beyond") or false

  -- log:debug("Loaded progress. Current: %d, Highest: %d", self.current_level, self.highest_level)
end

function BeyondManager:save_progress()
  local highest_level = tostring(self.highest_level)
  local current_level = tostring(self.current_level)

  ModSettingSet("kaleva_koetus.beyond_highest", highest_level)
  ModSettingSet("kaleva_koetus.beyond_current", current_level)

  ModSettingSetNextValue("kaleva_koetus.beyond_highest", highest_level, false)
  ModSettingSetNextValue("kaleva_koetus.beyond_current", current_level, false)

  -- log:debug("Saved progress. Current: %s, Highest: %s", current_level, highest_level)
end

function BeyondManager:_can_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_level then
    return self.highest_level < self.MAX_LEVEL
  end
  return false
end

-- TODO:
function BeyondManager:_add_beyond_info_park(player_entity_id)
  local beyond_perk_added = GlobalsGetValue("kaleva_koetus_beyond_perk_added", "false") == "true"
  if not beyond_perk_added then
    -- 処理
    local entity_ui = EntityCreateNew("")
    EntityAddTag(entity_ui, "perk_entity")

    local description = ""
    for i = 1, self.current_level, 1 do
      local line = GameTextGetTranslatedOrNot("$kaleva_koetus_specification_a" .. i) .. " [A" .. i .. "]" .. "\n"
      description = description .. line
    end

    local _ = EntityAddComponent2(entity_ui, "UIIconComponent", {
      name = "$kaleva_koetus_beyond_info_name",
      description = description,
      icon_sprite_file = "mods/kaleva_koetus/files/ui_gfx/beyonds/b" .. self.current_level .. ".png",
    })

    EntityAddChild(player_entity_id, entity_ui)

    GlobalsSetValue("kaleva_koetus_beyond_perk_added", "true")
  end
end

function BeyondManager:on_victory()
  -- log:info("Victory detected at level %d (highest unlocked %d)", self.current_level, self.highest_level)

  local current_beyond = self.active_beyonds[#self.active_beyonds]
  if not current_beyond or not current_beyond.should_unlock_next then
    self:save_progress()
    return
  end

  if current_beyond:should_unlock_next() then
    if self.current_level == 0 then
      log:warn("Victory with no beyond active (current level 0)")
      GamePrintImportant("Victory! (No beyond active)")
    elseif self:_can_unlock_next_level() then
      self.highest_level = self.highest_level + 1
      -- log:info("Beyond %d cleared. Unlocking %d", self.current_level, self.highest_level)
      GamePrintImportant("Beyond " .. self.current_level .. " Cleared! ", "Beyond " .. self.highest_level .. " Unlocked!")
      self.current_level = self.current_level + 1
    else
      -- log:info("Beyond %d cleared", self.current_level)
      GamePrintImportant("Beyond " .. self.current_level .. " Cleared! ")
    end
  end

  self:save_progress()
end

function BeyondManager:update()
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_update then
      beyond:on_update()
    end
  end
end

function BeyondManager:on_player_spawn(player_entity_id)
  local entity_id = tonumber(player_entity_id)
  if not entity_id then
    log:error("Invalid player entity id: %s", tostring(player_entity_id))
    return
  end

  log:info(#self.active_beyonds)
  log:info(self.active_beyonds[#self.active_beyonds])
  if self.current_level > 0 and self.active_beyonds[#self.active_beyonds].level == self.current_level then
    local translated_beyond = GameTextGetTranslatedOrNot("$kaleva_koetus_beyond")
    local translated_description = GameTextGetTranslatedOrNot(self.active_beyonds[#self.active_beyonds].description)
    GamePrintImportant(translated_beyond .. " " .. self.current_level, translated_description)
  end

  if ModSettingGet("kaleva_koetus.show_beyond_info") then
    BeyondManager:_add_beyond_info_park(player_entity_id)
  end

  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_player_spawn then
      beyond:on_player_spawn(entity_id)
    end
  end
end

function BeyondManager:on_world_initialized()
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_world_initialized then
      beyond:on_world_initialized()
    end
  end
end

function BeyondManager:on_biome_config_loaded()
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_biome_config_loaded then
      beyond:on_biome_config_loaded()
    end
  end
end

function BeyondManager:on_enemy_spawn(payload)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_enemy_spawn then
      beyond:on_enemy_spawn(payload)
    end
  end
end

function BeyondManager:on_enemy_post_spawn(payload)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_enemy_post_spawn then
      beyond:on_enemy_post_spawn(payload)
    end
  end
end

function BeyondManager:on_shop_card_spawn(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_shop_card_spawn then
      beyond:on_shop_card_spawn(event_args)
    end
  end
end

function BeyondManager:on_shop_wand_spawn(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_shop_wand_spawn then
      beyond:on_shop_wand_spawn(event_args)
    end
  end
end

function BeyondManager:on_necromancer_spawn(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_necromancer_spawn then
      beyond:on_necromancer_spawn(event_args)
    end
  end
end

function BeyondManager:on_potion_generated(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_potion_generated then
      beyond:on_potion_generated(event_args)
    end
  end
end

function BeyondManager:on_book_generated(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_book_generated then
      beyond:on_book_generated(event_args)
    end
  end
end

function BeyondManager:on_gold_spawn(event_args)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_gold_spawn then
      beyond:on_gold_spawn(event_args)
    end
  end
end

function BeyondManager:on_spell_generated(payload)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_spell_generated then
      beyond:on_spell_generated(payload)
    end
  end
end

function BeyondManager:on_mod_post_init(payload)
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_mod_post_init then
      beyond:on_mod_post_init(payload)
    end
  end
end

function BeyondManager:on_boss_died()
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_boss_died then
      beyond:on_boss_died()
    end
  end
end

function BeyondManager:on_new_game_plus_started()
  for _, beyond in ipairs(self.active_beyonds) do
    if beyond.on_new_game_plus_started then
      beyond:on_new_game_plus_started()
    end
  end
end

function BeyondManager:get_info()
  return {
    current = self.current_level,
    highest_level = self.highest_level,
    max_level = self.MAX_LEVEL,
    active = #self.active_beyonds > 0,
  }
end

return BeyondManager
