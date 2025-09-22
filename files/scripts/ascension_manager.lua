local AscensionManager = {}

-- Configuration
AscensionManager.MAX_LEVEL = 20

-- State
AscensionManager.current_level = 0
AscensionManager.highest_unlocked = 0
AscensionManager.active_ascensions = {}

-- Convert setting string to level number
function AscensionManager:convert_setting_to_level(setting_value)
  if setting_value == "disabled" then
    return 0
  end

  -- Extract number from "ascension_X" format
  local level = string.match(setting_value, "ascension_(%d+)")
  if level then
    return tonumber(level) or 0
  end

  return 0
end

-- Initialize the ascension system
function AscensionManager:init()
  print("[Kaleva Koetus] Initializing Ascension Manager")

  -- Load saved data
  self:load_progress()

  -- Set current run's ascension level from ModSettings
  local selected_level = 0

  local setting_value = ModSettingGet("kaleva_koetus.ascension_level") or "disabled"
  selected_level = self:convert_setting_to_level(setting_value)

  if selected_level > 0 and selected_level <= self.highest_unlocked then
    self:activate_ascension(selected_level)
  end
end

-- Load ascension for a specific level
function AscensionManager:load_ascension(level)
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
function AscensionManager:activate_ascension(level)
  print("[Kaleva Koetus] Activating Ascensions 1-" .. level)

  -- Clear current ascensions
  self.active_ascensions = {}
  self.current_level = level

  -- Load and activate all levels from 1 to specified level
  for i = 1, level do
    local ascension = self:load_ascension(i)
    if ascension then
      table.insert(self.active_ascensions, ascension)

      -- Call activation hook for each level
      if ascension.on_activate then
        ascension:on_activate()
      end

      print("[Kaleva Koetus] Activated Ascension " .. i)
    end
  end

  -- Store current level in ModSettings for persistence
  ModSettingSet("kaleva_koetus.ascension_current", tostring(level))

  if level > 0 then
    GamePrint("Ascensions 1-" .. level .. " Active (" .. #self.active_ascensions .. " effects)")
  end
end

-- Save progress
function AscensionManager:save_progress()
  ModSettingSet("kaleva_koetus.ascension_highest", tostring(self.highest_unlocked))
  print("[Kaleva Koetus] Saved progress. Highest unlocked: " .. self.highest_unlocked)
end

-- Load progress
function AscensionManager:load_progress()
  -- Load from ModSettings instead of Globals
  self.highest_unlocked = tonumber(ModSettingGet("kaleva_koetus.ascension_highest") or "0") or 0
  self.current_level = tonumber(ModSettingGet("kaleva_koetus.ascension_level") or "0") or 0

  print("[Kaleva Koetus] Loaded progress. Current: " .. self.current_level .. ", Highest unlocked: " .. self.highest_unlocked)
end

-- Unlock next ascension level
function AscensionManager:_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_unlocked then
    if self.highest_unlocked < self.MAX_LEVEL then
      self.highest_unlocked = self.highest_unlocked + 1
      self:save_progress()
      GamePrint("Unlocked Ascension " .. self.highest_unlocked .. "!")
      return true
    end
  end
  return false
end

function AscensionManager:on_victory()
  -- Display victory message with ascension info
  local info = self:get_ascension_info()
  if info.current > 0 then
    GamePrint("Victory on Ascension " .. info.current .. "!")
  end

  -- Check if should unlock next level
  local should_unlock = true

  -- Check all active ascensions for unlock conditions
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.should_unlock_next then
      if not ascension:should_unlock_next() then
        should_unlock = false
        break
      end
    end
  end

  if should_unlock then
    local unlocked = self:_unlock_next_level()
    if unlocked then
      GamePrint("Ascension " .. self.highest_unlocked .. " unlocked!")
    end
  end
end

-- Update (called every frame)
function AscensionManager:update()
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_update then
      ascension:on_update()
    end
  end
end

-- Player spawn handler
function AscensionManager:on_player_spawn(player_entity)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_player_spawn then
      ascension:on_player_spawn(player_entity)
    end
  end
end

-- Enemy spawn event handler
function AscensionManager:on_enemy_spawn(enemy_entity)
  for _, ascension in ipairs(self.active_ascensions) do
    if ascension.on_enemy_spawn then
      ascension:on_enemy_spawn(enemy_entity)
    end
  end
end

-- Get info for UI
function AscensionManager:get_ascension_info()
  return {
    current = self.current_level,
    highest_unlocked = self.highest_unlocked,
    max_level = self.MAX_LEVEL,
    active = #self.active_ascensions > 0,
  }
end

return AscensionManager
