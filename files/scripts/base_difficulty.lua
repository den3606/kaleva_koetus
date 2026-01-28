---@class Difficulty
---@field current_level number
---@field highest_level number
---@field single_ascension boolean
---@field active_ascensions table

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
---@field on_count_secrets fun(self: Difficulty): number, number?
local Difficulty = {
  current_level = 1,
  highest_level = 1,
  single_ascension = false,
  active_ascensions = {},
}

local MAX_LEVEL = 20

function Difficulty.get_max_level()
  return MAX_LEVEL
end

function Difficulty:get_ascension_info()
  return {
    current = self.current_level,
    highest_level = self.highest_level,
    max_level = self.get_max_level(),
    active = #self.active_ascensions > 0,
  }
end

function Difficulty:load_progress()
  self.highest_level = tonumber(ModSettingGet("kaleva_koetus.ascension_highest")) or self.highest_level
  self.current_level = tonumber(ModSettingGet("kaleva_koetus.ascension_current")) or self.current_level

  -- v1.0.00以前のセーブデータ対応
  if self.current_level == 0 or self.highest_level == 0 then
    self.highest_level = 1
    self.current_level = 1
  end

  local single_ascension_setting = ModSettingGet("kaleva_koetus.single_ascension")
  ---@cast single_ascension_setting boolean|nil
  self.single_ascension = single_ascension_setting or self.single_ascension
end

function Difficulty:save_progress()
  local highest_level = tostring(self.highest_level)
  local current_level = tostring(self.current_level)

  ModSettingSet("kaleva_koetus.ascension_highest", highest_level)
  ModSettingSet("kaleva_koetus.ascension_current", current_level)

  ModSettingSetNextValue("kaleva_koetus.ascension_highest", highest_level, false)
  ModSettingSetNextValue("kaleva_koetus.ascension_current", current_level, false)

  -- log:debug("Saved progress. Current: %s, Highest: %s", current_level, highest_level)
end

function Difficulty:can_unlock_next_level()
  if self.current_level > 0 and self.current_level == self.highest_level then
    return self.highest_level < self.get_max_level()
  end
  return false
end

return Difficulty
