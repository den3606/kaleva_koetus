---@alias difficulty_type "ascension"|"beyond"

---@class Difficulty
---@field current_difficulty difficulty_type
---@field current_level number
---@field highest_level number
---@field single_level boolean
---@field active_levels table

---@class Difficulty
---@field init fun(self: Difficulty)?
---@field on_mod_pre_init fun(self: Difficulty)?
---@field on_mod_init fun(self: Difficulty)?
---@field on_mod_post_init fun(self: Difficulty)?
---@field on_biome_config_loaded fun(self: Difficulty)?
---@field on_magic_numbers_and_world_seed_initialized fun(self: Difficulty)?
---@field on_world_initialized fun(self: Difficulty)?
---@field on_player_spawned fun(self: Difficulty, player_entity_id: number)?
---@field on_player_died fun(self: Difficulty, player_entity_id: number)?
---@field on_world_pre_update fun(self: Difficulty)?
---@field on_world_post_update fun(self: Difficulty)?
---@field on_paused_changed fun(self: Difficulty, is_paused: number, is_inventory_pause: number)?
---@field on_mod_settings_changed fun(self: Difficulty)?
---@field on_pause_pre_update fun(self: Difficulty)?
---@field on_count_secrets (fun(self: Difficulty): number, number)?
local Difficulty = {}
Difficulty.__index = Difficulty

local MAX_LEVEL = 20

---@type difficulty_type[]
local difficulty_list = {
  "ascension",
  "beyond",
}

---@param now_difficulty difficulty_type
---@return difficulty_type?
local function get_next_difficulty(now_difficulty)
  for i, difficulty in ipairs(difficulty_list) do
    if now_difficulty == difficulty then
      if i == #difficulty_list then
        return nil
      end

      return difficulty_list[i + 1]
    end
  end
end

---@param difficulty difficulty_type
local function is_difficulty_locked(difficulty)
  local highest_level = tonumber(ModSettingGet("kaleva_koetus." .. difficulty .. ".highest"))
  return highest_level == nil or highest_level == 0
end

---@param difficulty difficulty_type
local function unlock_difficulty(difficulty)
  local highest_level = tonumber(ModSettingGet("kaleva_koetus." .. difficulty .. ".highest")) or 0
  if highest_level == 0 then
    ModSettingSet("kaleva_koetus." .. difficulty .. ".highest", tostring(1))
  end
end

function Difficulty.get_max_level()
  return MAX_LEVEL
end

function Difficulty:get_info()
  return {
    current = self.current_level,
    highest_level = self.highest_level,
    max_level = self.get_max_level(),
    active = #self.active_levels > 0,
  }
end

---@param difficulty difficulty_type
---@return number? current_level
---@return number? highest_level
local function get_progress(difficulty)
  local current_level = tonumber(ModSettingGet("kaleva_koetus." .. difficulty .. ".current"))
  local highest_level = tonumber(ModSettingGet("kaleva_koetus." .. difficulty .. ".highest"))
  return current_level, highest_level
end

function Difficulty:load_progress()
  local current_level, highest_level = get_progress(self.current_difficulty)
  self.current_level = current_level or self.current_level
  self.highest_level = highest_level or self.highest_level

  local single_level_setting = ModSettingGet("kaleva_koetus." .. self.current_difficulty .. ".single")
  ---@cast single_level_setting boolean|nil
  self.single_level = single_level_setting or self.single_level
end

function Difficulty:update_progress()
  if self.current_level == 0 then
    return
  end

  if self.current_level < self.highest_level then
    return
  end

  if self.highest_level < self.get_max_level() then
    local new_current_level = self.highest_level + 1
    local new_highest_level = self.highest_level + 1

    local _, old_highest_level = get_progress(self.current_difficulty)
    if old_highest_level >= new_highest_level then
      return
    end

    ModSettingSetNextValue("kaleva_koetus." .. self.current_difficulty .. ".current", tostring(new_current_level), false)
    ModSettingSet("kaleva_koetus." .. self.current_difficulty .. ".highest", tostring(new_highest_level))
  else
    ModSettingSet("kaleva_koetus." .. self.current_difficulty .. ".cleared", true)

    local next_difficulty = get_next_difficulty(self.current_difficulty)
    if next_difficulty and is_difficulty_locked(next_difficulty) then
      unlock_difficulty(next_difficulty)

      ModSettingSetNextValue("kaleva_koetus.current_difficulty", next_difficulty, false)
    end
  end
end

function Difficulty:should_show_info()
  return ModSettingGet("kaleva_koetus." .. self.current_difficulty .. ".show_info")
end

function Difficulty:will_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_level then
    return self.highest_level < self.get_max_level()
  end
  return false
end

function Difficulty:will_unlock_next_difficulty()
  if self.current_level < self.get_max_level() then
    return false
  end

  local next_difficulty = get_next_difficulty(self.current_difficulty)
  if not next_difficulty then
    return false
  end

  return is_difficulty_locked(next_difficulty)
end

---@class DifficultyManager
local DifficultyManager = {}

---@param difficulty difficulty_type
function DifficultyManager.create(difficulty)
  return setmetatable({
    current_difficulty = difficulty,
    current_level = 0,
    highest_level = 0,
    single_level = false,
    active_levels = {},
  }, Difficulty)
end

function DifficultyManager.get_current_difficulty()
  local current_difficulty = ModSettingGet("kaleva_koetus.current_difficulty")
  ---@cast current_difficulty string|nil
  return current_difficulty
end

return DifficultyManager
