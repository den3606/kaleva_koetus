local _ = dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "kaleva_koetus"

---@type string
local difficulty_cache

---@param base_id string
---@vararg string
local function sub_id(base_id, ...)
  return table.concat({ base_id, ... }, ".")
end

---@param difficulty string
---@return number
local function get_max_level(difficulty)
  local setting_max_level = tonumber(ModSettingGet(sub_id(mod_id, difficulty, "highest")))
  return setting_max_level or 0
end

---@param difficulty string
---@param level number
local function set_max_level(difficulty, level)
  ModSettingSet(sub_id(mod_id, difficulty, "highest"), tostring(level))
end

---@param difficulty_name string
---@param max_level number
---@return table
local function get_level_enum(difficulty_name, max_level)
  local values = {}
  for i = 1, max_level do
    table.insert(values, {
      tostring(i),
      difficulty_name .. " " .. tostring(i),
    })
  end

  return values
end

---@class Difficulty_Setting
---@field id string
---@field ui_name string
---@field current table
---@field show_info table
---@field is_unlocked fun():boolean
---@field is_cleared fun():boolean
---@field update fun(self:Difficulty_Setting ,current_difficulty: string)
local Difficulty_Setting = {}
Difficulty_Setting.__index = Difficulty_Setting

---@param is_hidden boolean
function Difficulty_Setting:set_hidden(is_hidden)
  for _, v in pairs(self) do
    if type(v) == "table" then
      v.hidden = is_hidden
    end
  end
end

function Difficulty_Setting:update(current_difficulty)
  self:set_hidden(current_difficulty ~= self.id)
  local max_level = get_max_level(self.id)
  if max_level > 0 then
    self.current.values = get_level_enum(self.ui_name, max_level)
    self.current.value_default = tostring(max_level)
    self.show_info.value_default = true
  else
    self.current.values = nil
    self.current.value_default = nil
    self.show_info.value_default = nil

    self.current.hidden = true
    self.show_info.hidden = true
  end
end

local ascension = setmetatable({
  id = "ascension",
  ui_name = "Ascension",
}, Difficulty_Setting)
ascension.current = {
  id = sub_id(ascension.id, "current"),
  ui_name = "Ascension Level",
  ui_description = "Select the ascension level for this run",
  scope = MOD_SETTING_SCOPE_NEW_GAME,
}
ascension.show_info = {
  id = sub_id(ascension.id, "show_info"),
  ui_name = "Show Ascension Info",
  ui_description = "Display current ascension level and effects during gameplay",
  scope = MOD_SETTING_SCOPE_NEW_GAME,
}
function ascension.is_unlocked()
  return true
end
function ascension.is_cleared()
  return ModSettingGet(sub_id(mod_id, ascension.id, "cleared")) == true
end

local beyond = setmetatable({
  id = "beyond",
  ui_name = "Beyond",
}, Difficulty_Setting)
beyond.current = {
  id = sub_id(beyond.id, "current"),
  ui_name = "Beyond Level",
  ui_description = "Select the beyond level for this run",
  scope = MOD_SETTING_SCOPE_NEW_GAME,
}
beyond.show_info = {
  id = sub_id(beyond.id, "show_info"),
  ui_name = "Show Beyond Info",
  ui_description = "Display current beyond level and effects during gameplay",
  scope = MOD_SETTING_SCOPE_NEW_GAME,
}
function beyond.is_unlocked()
  return ascension.is_cleared()
end
function beyond.is_cleared()
  return ModSettingGet(sub_id(mod_id, beyond.id, "cleared")) == true
end

local current_difficulty = {
  id = "current_difficulty",
  ui_name = "Select Difficulty",
  ui_description = "You can change the difficulty mode.",
  scope = MOD_SETTING_SCOPE_NEW_GAME,
  change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, new_value)
    difficulty_cache = new_value
  end,
}
function current_difficulty:update()
  self.values = {}
  self.value_default = nil

  local difficulties = { ascension, beyond }

  for _, difficulty in ipairs(difficulties) do
    if difficulty.is_unlocked() then
      table.insert(self.values, { difficulty.id, difficulty.ui_name })
      self.value_default = difficulty.id
    end
  end

  self.hidden = #self.values <= 1
end

---@param update_difficulty_cache boolean?
local function update_settings(update_difficulty_cache)
  current_difficulty:update()
  if update_difficulty_cache then
    local difficulty = ModSettingGetNextValue("kaleva_koetus.current_difficulty") or current_difficulty.value_default
    ---@cast difficulty string
    difficulty_cache = difficulty
  end
  ascension:update(difficulty_cache)
  beyond:update(difficulty_cache)
end

-- Define mod settings
mod_settings_version = 2
mod_settings = {
  {
    category_id = "ascension_settings",
    ui_name = "Ascension Settings",
    ui_description = "Configure ascension level for your run",
    settings = {
      current_difficulty,
      ascension.current,
      ascension.show_info,
      beyond.current,
      beyond.show_info,
    },
  },
  {
    category_id = "debug_settings",
    ui_name = "Debug Settings",
    ui_description = "Debug options for testing",
    foldable = true,
    _folded = true,
    settings = {
      {
        id = "log_level",
        ui_name = "Log Level",
        ui_description = "Select verbosity for Kaleva Koetus logs",
        value_default = "INFO",
        values = {
          { "ERROR", "Error" },
          { "WARN", "Warn" },
          { "INFO", "Info" },
          { "DEBUG", "Debug" },
          { "VERBOSE", "Verbose" },
        },
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = sub_id(ascension.id, "single"),
        ui_name = "Single Ascension",
        ui_description = "Activate only one ascension",
        value_default = false,
        scope = MOD_SETTING_SCOPE_NEW_GAME,
      },
      {
        id = sub_id(beyond.id, "single"),
        ui_name = "Single Beyond",
        ui_description = "Activate only one beyond",
        value_default = false,
        scope = MOD_SETTING_SCOPE_NEW_GAME,
      },
      {
        id = "lock_all",
        ui_name = "Lock All Difficulties",
        ui_description = "Instantly lock all difficulty levels (for testing)",
        value_default = "Click to lock difficulties",
        values = { { "ok", "OK" } },
        scope = MOD_SETTING_SCOPE_RUNTIME,
        change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
          -- Unlock all levels
          ModSettingSetNextValue(sub_id(mod_id, "current_difficulty"), "ascension", false)
          difficulty_cache = "ascension"
          -- mod_setting_enum fallback to first enum when find no fitted one.
          -- Manually SetNextValue to avoid confusing.
          ModSettingSetNextValue(sub_id(mod_id, ascension.id, "current"), tostring(1), false)

          set_max_level(ascension.id, 1)
          set_max_level(beyond.id, 0)

          print("[Kaleva Koetus] All ascensions locked!")
          print("[Kaleva Koetus] All beyonds locked!")
        end,
      },
      {
        id = "unlock_all",
        ui_name = "Unlock All Difficulties",
        ui_description = "Instantly unlock all difficulty levels (for testing)",
        value_default = "Click to unlock difficulties",
        values = { { "ok", "OK" } },
        scope = MOD_SETTING_SCOPE_RUNTIME,
        change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
          -- Unlock all levels
          set_max_level(ascension.id, 20)
          set_max_level(beyond.id, 20)

          print("[Kaleva Koetus] All ascensions unlocked!")
          print("[Kaleva Koetus] All beyonds unlocked!")
        end,
      },
    },
  },
}

-- This function is called when the game is initializing settings
function ModSettingsUpdate(init_scope)
  --------------------------------------------------
  -- Updating Start. No external dependency.
  --------------------------------------------------

  local old_version = mod_settings_get_version(mod_id)

  ---@param old_id string
  ---@param new_id string
  ---@param process_value (fun(value:any, value_next:any):any, any)?
  local function migrate_setting(old_id, new_id, process_value)
    local value = ModSettingGet(old_id)
    local value_next = ModSettingGetNextValue(old_id)
    if process_value then
      value, value_next = process_value(value, value_next)
    end
    if value ~= nil then
      ModSettingSet(new_id, value)
    end
    if value_next ~= nil then
      ModSettingSetNextValue(new_id, value_next, false)
    end
    local _ = ModSettingRemove(old_id)
  end

  if old_version == 0 then
    ModSettingSet("kaleva_koetus.ascension_current", tostring(1))
    ModSettingSet("kaleva_koetus.ascension_highest", tostring(1))

    old_version = 1
  end

  if old_version == 1 then
    ModSettingSet("kaleva_koetus.current_difficulty", "ascension")
    if ModSettingGet("kaleva_koetus.ascension.cleared") == true then
      ModSettingSet("kaleva_koetus.beyond.highest", tostring(1))
      ModSettingSetNextValue("kaleva_koetus.current_difficulty", "beyond", false)
    end

    local _ = ModSettingRemove("kaleva_koetus.gun_action_seed")
    _ = ModSettingRemove("kaleva_koetus.a20_dead_boss")

    migrate_setting("kaleva_koetus.ascension_current", "kaleva_koetus.ascension.current", function(value, value_next)
      if value and tonumber(value) == 0 then
        value = tostring(1)
      end
      if value_next and tonumber(value_next) == 0 then
        value_next = tostring(1)
      end
      return value, value_next
    end)
    migrate_setting("kaleva_koetus.ascension_highest", "kaleva_koetus.ascension.highest", function(value, _value_next)
      if value and tonumber(value) == 0 then
        value = tostring(1)
      end
      return value, nil
    end)
    migrate_setting("kaleva_koetus.show_ascension_info", "kaleva_koetus.ascension.show_info")
    migrate_setting("kaleva_koetus.single_level", "kaleva_koetus.ascension.single")

    old_version = 2
  end

  --------------------------------------------------
  -- Updating End.
  --------------------------------------------------

  update_settings(true)

  mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the current value of the setting
function ModSettingsGuiCount()
  return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called when drawing the settings UI
function ModSettingsGui(gui, in_main_menu)
  update_settings()
  mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
