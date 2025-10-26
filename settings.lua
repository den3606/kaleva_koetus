local _ = dofile_once("data/scripts/lib/mod_settings.lua")
local mod_id = "kaleva_koetus"

local debug_combo_latched = false

local function detect_debug_combo_press()
  _ = dofile_once("data/scripts/debug/keycodes.lua")

  -- selene: allow(undefined_variable)
  local key_d = Key_d
  -- selene: allow(undefined_variable)
  local key_b = Key_b
  -- selene: allow(undefined_variable)
  local key_g = Key_g

  if not (key_d and key_b and key_g) then
    return false
  end

  local all_pressed = InputIsKeyDown(key_d) and InputIsKeyDown(key_b) and InputIsKeyDown(key_g)
  if not all_pressed then
    debug_combo_latched = false
    return false
  end

  if debug_combo_latched then
    return false
  end

  if InputIsKeyJustDown(key_d) or InputIsKeyJustDown(key_b) or InputIsKeyJustDown(key_g) then
    debug_combo_latched = true
    return true
  end

  return false
end

local build_mod_settings -- forward declaration
local debug_settings_visible = false

local function apply_debug_settings_toggle()
  if detect_debug_combo_press() then
    debug_settings_visible = not debug_settings_visible
    if build_mod_settings then
      build_mod_settings()
    end
  end
end

----------------------------------------
--- Ascension Settings
----------------------------------------

local ascension_setting

local function get_ascension_values()
  local values = {}
  local max_level = ModSettingGet("kaleva_koetus.ascension_highest") or 1
  -- Add unlocked ascension levels
  for i = 1, math.max(max_level, 1) do -- Show at least level 1 for testing
    table.insert(values, {
      tostring(i),
      "Ascension " .. i,
    })
  end

  return values
end

local function locate_ascension_setting()
  if ascension_setting ~= nil then
    return ascension_setting
  end

  if not mod_settings then
    return nil
  end

  local function search_ascension(settings)
    for _, setting in ipairs(settings) do
      if setting.id == "ascension_current" then
        ascension_setting = setting
        return true
      end

      if setting.settings and search_ascension(setting.settings) then
        return true
      end
    end

    return false
  end

  for _, category in ipairs(mod_settings) do
    if category.settings and search_ascension(category.settings) then
      break
    end
  end

  return ascension_setting
end

local function update_ascension_setting_values()
  local setting = locate_ascension_setting()
  if setting then
    setting.values = get_ascension_values()
  end
end

-- selene: allow(unused_variable)
local function reset_ascension_level()
  ascension_setting = nil
  update_ascension_setting_values()
end

local function display_ascension_settings()
  return {
    {
      id = "ascension_current",
      ui_name = "Ascension Level",
      ui_description = "Select the ascension level for this run",
      value_default = "1",
      values = get_ascension_values(),
      scope = MOD_SETTING_SCOPE_NEW_GAME,
    },
    {
      id = "show_ascension_info",
      ui_name = "Show Ascension Info",
      ui_description = "Display current ascension level and effects during gameplay",
      value_default = true,
      scope = MOD_SETTING_SCOPE_NEW_GAME,
    },
  }
end

----------------------------------------
--- Beyond Settings
----------------------------------------

local beyond_setting

local function get_beyond_values()
  local values = {}
  local max_level = ModSettingGet("kaleva_koetus.beyond_highest") or 1
  -- Add unlocked ascension levels
  for i = 1, math.max(max_level, 1) do -- Show at least level 1 for testing
    table.insert(values, {
      tostring(i),
      "Beyond " .. i,
    })
  end

  return values
end

local function locate_beyond_setting()
  if beyond_setting ~= nil then
    return beyond_setting
  end

  if not mod_settings then
    return nil
  end

  local function search_beyond(settings)
    for _, setting in ipairs(settings) do
      if setting.id == "beyond_current" then
        beyond_setting = setting
        return true
      end

      if setting.settings and search_beyond(setting.settings) then
        return true
      end
    end

    return false
  end

  for _, category in ipairs(mod_settings) do
    if category.settings and search_beyond(category.settings) then
      break
    end
  end

  return beyond_setting
end

local function update_beyond_setting_values()
  local setting = locate_beyond_setting()
  if setting then
    setting.values = get_beyond_values()
  end
end

-- selene: allow(unused_variable)
local function reset_beyond_level()
  beyond_setting = nil
  update_beyond_setting_values()
end

local function display_beyond_settings()
  return {
    {
      id = "beyond_current",
      ui_name = "Beyond Level",
      ui_description = "Select the beyond level for this run",
      value_default = "1",
      values = get_beyond_values(),
      scope = MOD_SETTING_SCOPE_NEW_GAME,
    },
    {
      id = "show_beyond_info",
      ui_name = "Show Beyond Info",
      ui_description = "Display current beyond level and effects during gameplay",
      value_default = true,
      scope = MOD_SETTING_SCOPE_NEW_GAME,
    },
  }
end

----------------------------------------
--- Mod Settings
----------------------------------------
-- This function is called when the game is initializing settings
function ModSettingsUpdate(init_scope)
  local _old_version = mod_settings_get_version(mod_id)
  update_ascension_setting_values()
  update_beyond_setting_values()
  mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the current value of the setting
function ModSettingsGuiCount()
  return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called when drawing the settings UI
function ModSettingsGui(gui, in_main_menu)
  update_ascension_setting_values()
  update_beyond_setting_values()
  apply_debug_settings_toggle()
  mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

----------------------------------------
--- Mod Settings (customize field)
----------------------------------------
local display_difficulty_settings = display_ascension_settings()
local switch_difficulty
local debug_settings_category

build_mod_settings = function()
  mod_settings = {}

  if ModSettingGet("kaleva_koetus.has_cleared_max_level") then
    table.insert(mod_settings, switch_difficulty)
  end

  for _, setting in ipairs(display_difficulty_settings) do
    table.insert(mod_settings, setting)
  end

  if debug_settings_visible and debug_settings_category then
    table.insert(mod_settings, debug_settings_category)
  end
end

local function select_display_difficulty(difficulty_name)
  if difficulty_name == "beyond" then
    display_difficulty_settings = display_beyond_settings()
    build_mod_settings()
  elseif difficulty_name == "ascension" then
    display_difficulty_settings = display_ascension_settings()
    build_mod_settings()
  else
    error("Unknown difficulty name: " .. tostring(difficulty_name))
  end
end

if ModSettingGet("kaleva_koetus.has_cleared_a20") == true then
  switch_difficulty = {
    id = "select_difficulty",
    ui_name = "Select Difficulty",
    ui_description = "You can change the difficulty mode.",
    value_default = "Click to change difficulties",
    values = { { "ascension", "Ascension" }, { "beyond", "Beyond" } },
    scope = MOD_SETTING_SCOPE_RUNTIME,
    change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
      select_display_difficulty(_new_value)
    end,
  }
end

debug_settings_category = {
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
      id = "single_ascension",
      ui_name = "Single Ascension",
      ui_description = "Activate only one ascension",
      value_default = false,
      scope = MOD_SETTING_SCOPE_NEW_GAME,
    },
    {
      id = "single_beyond",
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
        ModSettingSet("kaleva_koetus.ascension_highest", "1")
        ModSettingSet("kaleva_koetus.beyond_highest", "1")
        reset_ascension_level()
        reset_beyond_level()

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
        ModSettingSet("kaleva_koetus.ascension_highest", "20")
        ModSettingSet("kaleva_koetus.beyond_highest", "20")
        reset_ascension_level()
        reset_beyond_level()

        print("[Kaleva Koetus] All ascensions unlocked!")
        print("[Kaleva Koetus] All beyonds unlocked!")
      end,
    },
    {
      id = "toggle_beyond_mode_display",
      ui_name = "Switch Display Beyond Mode",
      ui_description = "Switch Beyond Mode display",
      value_default = "Click to switch beyond mode display",
      values = { { "ok", "OK" } },
      scope = MOD_SETTING_SCOPE_RUNTIME,
      change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
        local toggled = not (ModSettingGet("kaleva_koetus.has_cleared_max_level") == true)
        ModSettingSet("kaleva_koetus.has_cleared_max_level", toggled)
        select_display_difficulty("ascension")
      end,
    },
  },
}

build_mod_settings()

mod_settings_version = 1
