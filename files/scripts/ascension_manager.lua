local AscensionManager = {}

AscensionManager.MAX_LEVEL = 20

-- State
AscensionManager.current_level = 0
AscensionManager.highest_level = 0
AscensionManager.active_ascensions = {}

function AscensionManager:init()
  print("[Kaleva Koetus] Initializing Ascension Manager")

  -- Load saved data
  self:load_progress()

  -- Activate ascension if current_level is set
  if self.current_level > 0 and self.current_level <= self.highest_level then
    self:activate_ascension(self.current_level)
    print("[Kaleva Koetus] Start Ascension " .. self.current_level)
  else
    print("[Kaleva Koetus] No valid ascension to activate (current: " .. self.current_level .. ", unlocked: " .. self.highest_level .. ")")
  end
end

function AscensionManager:_load_ascension(level)
  if level < 1 or level > self.MAX_LEVEL then
    print("[Kaleva Koetus] Invalid ascension level: " .. tostring(level))
    return nil
  end

  local path = "mods/kaleva_koetus/files/scripts/ascensions/A" .. level .. ".lua"
  local success, ascension = pcall(dofile, path)

  if success then
    print("[Kaleva Koetus] Loaded Ascension " .. level)
    return ascension
  else
    print("[Kaleva Koetus] Failed to load Ascension " .. level .. ": " .. tostring(ascension))
    return nil
  end
end

-- Activate all ascension levels up to the specified level
function AscensionManager:activate_ascension()
  print("[Kaleva Koetus] Activating Ascensions 1-" .. self.current_level)

  -- Clear current ascensions
  self.active_ascensions = {}

  -- Load and activate all levels from 1 to specified level
  for i = 1, self.current_level do
    local ascension = self:_load_ascension(i)
    if ascension then
      table.insert(self.active_ascensions, ascension)

      -- Call activation hook for each level
      if ascension.on_activate then
        ascension:on_activate()
      end

      print("[Kaleva Koetus] Activated Ascension " .. i)
    end
  end

  if self.current_level > 0 then
    GamePrint("Ascensions 1-" .. self.current_level .. " Active (" .. #self.active_ascensions .. " effects)")
  end
end

function AscensionManager:load_progress()
  -- Load from ModSettings
  self.highest_level = tonumber(ModSettingGet("kaleva_koetus.ascension_highest") or "0") or 0
  self.current_level = tonumber(ModSettingGet("kaleva_koetus.ascension_current") or "0") or 0

  print("[Kaleva Koetus] Loaded progress. Current: " .. self.current_level .. ", Highest: " .. self.highest_level)
end

function AscensionManager:save_progress()
  ModSettingSet("kaleva_koetus.ascension_highest", tostring(self.highest_level))
  ModSettingSet("kaleva_koetus.ascension_current", tostring(self.current_level))

  local highest_level = tonumber(ModSettingGet("kaleva_koetus.ascension_highest") or "0") or 0
  local current_level = tonumber(ModSettingGet("kaleva_koetus.ascension_current") or "0") or 0

  print("[Kaleva Koetus] Saved progress. Current: " .. current_level .. ", Highest: " .. highest_level)
end

function AscensionManager:_can_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_level then
    return self.highest_level < self.MAX_LEVEL
  end
  return false
end

function AscensionManager:on_victory()
  print("[AscensionManager] on_victory called")

  print("[AscensionManager] Current level: " .. self.current_level .. ", Highest unlocked: " .. self.highest_level)

  if self.active_ascensions[self.current_level]:should_unlock_next() then
    if self.current_level == 0 then
      print("[AscensionManager] No ascension active (current_level = 0)")
      GamePrintImportant("Victory! (No ascension active)")
    elseif self:_can_unlock_next_level() then
      self.highest_level = self.highest_level + 1
      print("[Kaleva Koetus] Victory on Ascension " .. self.current_level .. "!")
      GamePrintImportant("Victory on Ascension " .. self.current_level .. "!", "Ascension " .. self.highest_level .. " unlocked!")
      self.current_level = self.current_level + 1
    else
      print("[Kaleva Koetus] Victory on Ascension " .. self.current_level .. "!")
      GamePrintImportant("Victory on Ascension " .. self.current_level .. "!")
    end
  end

  self:save_progress()
end

-- Update (called every frame)
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
    print("[AscensionManager] Invalid player entity id: " .. tostring(player_entity_id))
    return
  end

  GamePrintImportant("Ascension " .. self.current_level, self.active_ascensions[self.current_level].description)

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_player_spawn then
      ascension:on_player_spawn(entity_id)
    end
  end
end

function AscensionManager:on_enemy_spawn(payload)
  if #payload == 0 then
    error("[AscensionManager] No enemy entity in payload!")
    return
  end
  for _i, ascension in ipairs(self.active_ascensions) do
    if ascension.on_enemy_spawn then
      if #payload > 0 then
        ascension:on_enemy_spawn(payload)
      end
    end
  end
end

function AscensionManager:on_shop_card_spawn(event_args)
  if #event_args == 0 then
    error("[AscensionManager] No enemy entity in event_args!")
    return
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_card_spawn then
      ascension:on_shop_card_spawn(event_args)
    end
  end
end

function AscensionManager:on_shop_wand_spawn(event_args)
  if #event_args == 0 then
    error("[AscensionManager] No enemy entity in event_args!")
    return
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_shop_wand_spawn then
      ascension:on_shop_wand_spawn(event_args)
    end
  end
end

function AscensionManager:on_necromancer_spawn(event_args)
  if #event_args == 0 then
    error("[AscensionManager] No necromancer positions in event_args!")
    return
  end

  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_necromancer_spawn then
      ascension:on_necromancer_spawn(event_args)
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
