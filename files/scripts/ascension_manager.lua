local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("ascension_manager.lua")

local AscensionManager = {}

AscensionManager.MAX_LEVEL = 20

-- State
AscensionManager.current_level = 0
AscensionManager.highest_level = 0
AscensionManager.single_ascension = false
AscensionManager.active_ascensions = {}

function AscensionManager:init()
  -- log:info("Initializing Ascension Manager")

  -- Load saved data
  self:load_progress()

  -- Activate ascension if current_level is set
  if self.current_level > 0 and self.current_level <= self.highest_level then
    self:activate_ascension(self.current_level)
    -- log:info("Start Ascension %d", self.current_level)
  else
    -- log:warn("No valid ascension to activate (current: %d, unlocked: %d)", self.current_level, self.highest_level)
  end
end

function AscensionManager:_load_ascension(level)
  if level < 1 or level > self.MAX_LEVEL then
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

  self.active_ascensions = {}

  if self.single_ascension then
    local ascension = self:_load_ascension(self.current_level)
    if ascension then
      table.insert(self.active_ascensions, ascension)

      if ascension.on_activate then
        ascension:on_activate()
      end

      -- log:debug("Activated Ascension %d", self.current_level)
    end
  else
    for i = 1, self.current_level do
      local ascension = self:_load_ascension(i)
      if ascension then
        table.insert(self.active_ascensions, ascension)

        if ascension.on_activate then
          ascension:on_activate()
        end

        -- log:debug("Activated Ascension %d", i)
      end
    end

    if self.current_level > 0 then
      GamePrint("[Kaleva Koetus] Ascensions 1-" .. self.current_level .. " Active (" .. #self.active_ascensions .. " effects)")
    end
  end
end

function AscensionManager:load_progress()
  self.highest_level = tonumber(ModSettingGet("kaleva_koetus.ascension_highest") or "0") or 0
  self.current_level = tonumber(ModSettingGet("kaleva_koetus.ascension_current") or "0") or 0
  self.single_ascension = ModSettingGet("kaleva_koetus.single_ascension") or false

  -- log:debug("Loaded progress. Current: %d, Highest: %d", self.current_level, self.highest_level)
end

function AscensionManager:save_progress()
  local highest_level = tostring(self.highest_level)
  local current_level = tostring(self.current_level)

  ModSettingSet("kaleva_koetus.ascension_highest", highest_level)
  ModSettingSet("kaleva_koetus.ascension_current", current_level)

  ModSettingSetNextValue("kaleva_koetus.ascension_highest", highest_level, false)
  ModSettingSetNextValue("kaleva_koetus.ascension_current", current_level, false)

  -- log:debug("Saved progress. Current: %s, Highest: %s", current_level, highest_level)
end

function AscensionManager:_can_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_level then
    return self.highest_level < self.MAX_LEVEL
  end
  return false
end

-- TODO:
function AscensionManager:_add_ascension_info_park(player_entity_id)
  local ascension_perk_added = GlobalsGetValue("kaleva_koetus_ascension_perk_added", "false") == "true"
  if not ascension_perk_added then
    -- 処理
    local entity_ui = EntityCreateNew("")
    EntityAddTag(entity_ui, "perk_entity")

    local description = ""
    for i = 1, self.current_level, 1 do
      local line = GameTextGetTranslatedOrNot("$kaleva_koetus_specification_a" .. i) .. " [A" .. i .. "]" .. "\n"
      description = description .. line
    end

    local _ = EntityAddComponent2(entity_ui, "UIIconComponent", {
      name = "$kaleva_koetus_ascension_info_name",
      description = description,
      icon_sprite_file = "mods/kaleva_koetus/files/ui_gfx/ascensions/a" .. self.current_level .. ".png",
    })

    EntityAddChild(player_entity_id, entity_ui)

    GlobalsSetValue("kaleva_koetus_ascension_perk_added", "true")
  end
end

function AscensionManager:on_victory()
  -- log:info("Victory detected at level %d (highest unlocked %d)", self.current_level, self.highest_level)

  local current_ascension = self.active_ascensions[#self.active_ascensions]
  if not current_ascension or not current_ascension.should_unlock_next then
    self:save_progress()
    return
  end

  if current_ascension:should_unlock_next() then
    if self.current_level == 0 then
      -- log:warn("Victory with no ascension active (current level 0)")
      GamePrintImportant("Victory! (No ascension active)")
    elseif self:_can_unlock_next_level() then
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
end

function AscensionManager:update()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_update then
      ascension:on_update()
    end
  end
end

function AscensionManager:on_player_spawn(player_entity_id)
  local entity_id = tonumber(player_entity_id)
  if not entity_id then
    log:error("Invalid player entity id: %s", tostring(player_entity_id))
    return
  end
  if self.current_level > 0 and self.active_ascensions[#self.active_ascensions].level == self.current_level then
    local translated_ascension = GameTextGetTranslatedOrNot("$kaleva_koetus_ascension")
    local translated_description = GameTextGetTranslatedOrNot(self.active_ascensions[#self.active_ascensions].description)
    GamePrintImportant(translated_ascension .. " " .. self.current_level, translated_description)
  end

  if ModSettingGet("kaleva_koetus.show_ascension_info") then
    AscensionManager:_add_ascension_info_park(player_entity_id)
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_player_spawn then
      ascension:on_player_spawn(entity_id)
    end
  end
end

function AscensionManager:on_world_initialized()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_world_initialized then
      ascension:on_world_initialized()
    end
  end
end

function AscensionManager:on_enemy_spawn(payload)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_enemy_spawn then
      ascension:on_enemy_spawn(payload)
    end
  end
end

function AscensionManager:on_shop_card_spawn(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_card_spawn then
      ascension:on_shop_card_spawn(event_args)
    end
  end
end

function AscensionManager:on_shop_wand_spawn(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_wand_spawn then
      ascension:on_shop_wand_spawn(event_args)
    end
  end
end

function AscensionManager:on_necromancer_spawn(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_necromancer_spawn then
      ascension:on_necromancer_spawn(event_args)
    end
  end
end

function AscensionManager:on_potion_generated(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_potion_generated then
      ascension:on_potion_generated(event_args)
    end
  end
end

function AscensionManager:on_book_generated(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_book_generated then
      ascension:on_book_generated(event_args)
    end
  end
end

function AscensionManager:on_fungal_shifted()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_fungal_shifted then
      ascension:on_fungal_shifted()
    end
  end
end

function AscensionManager:on_fungal_shift_curse_released()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_fungal_shift_curse_released then
      ascension:on_fungal_shift_curse_released()
    end
  end
end

function AscensionManager:on_gold_spawn(event_args)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_gold_spawn then
      ascension:on_gold_spawn(event_args)
    end
  end
end

function AscensionManager:on_spell_generated(payload)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_spell_generated then
      ascension:on_spell_generated(payload)
    end
  end
end

function AscensionManager:on_mod_post_init(payload)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_mod_post_init then
      ascension:on_mod_post_init(payload)
    end
  end
end

function AscensionManager:on_boss_died()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_boss_died then
      ascension:on_boss_died()
    end
  end
end

function AscensionManager:get_ascension_info()
  return {
    current = self.current_level,
    highest_level = self.highest_level,
    max_level = self.MAX_LEVEL,
    active = #self.active_ascensions > 0,
  }
end

return AscensionManager
