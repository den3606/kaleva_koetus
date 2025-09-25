local _ = dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "kaleva_koetus"
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

  local function search(settings)
    for _, setting in ipairs(settings) do
      if setting.id == "ascension_current" then
        ascension_setting = setting
        return true
      end

      if setting.settings and search(setting.settings) then
        return true
      end
    end

    return false
  end

  for _, category in ipairs(mod_settings) do
    if category.settings and search(category.settings) then
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

local function reset_ascension_level()
  ascension_setting = nil
  update_ascension_setting_values()
end

-- This function is called when the game is initializing settings
function ModSettingsUpdate(init_scope)
  local _old_version = mod_settings_get_version(mod_id)
  update_ascension_setting_values()
  mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the current value of the setting
function ModSettingsGuiCount()
  return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called when drawing the settings UI
function ModSettingsGui(gui, in_main_menu)
  update_ascension_setting_values()
  mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

-- Define mod settings
mod_settings_version = 1
mod_settings = {
  {
    category_id = "ascension_settings",
    ui_name = "Ascension Settings",
    ui_description = "Configure ascension level for your run",
    settings = {
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
        scope = MOD_SETTING_SCOPE_RUNTIME,
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
              { "TRACE", "Trace" },
            },
            scope = MOD_SETTING_SCOPE_RUNTIME,
          },
          {
            id = "lock_all",
            ui_name = "Lock All Ascensions",
            ui_description = "Instantly lock all ascension levels (for testing)",
            value_default = "Click to lock ascension",
            values = { { "ok", "OK" } },
            scope = MOD_SETTING_SCOPE_RUNTIME,
            change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
              -- Unlock all levels
              ModSettingSet("kaleva_koetus.ascension_highest", "1")
              reset_ascension_level()

              print("[Kaleva Koetus] All ascensions locked!")
            end,
          },
          {
            id = "unlock_all",
            ui_name = "Unlock All Ascensions",
            ui_description = "Instantly unlock all ascension levels (for testing)",
            value_default = "Click to unlock ascension",
            values = { { "ok", "OK" } },
            scope = MOD_SETTING_SCOPE_RUNTIME,
            change_fn = function(_mod_id, _gui, _in_main_menu, _setting, _old_value, _new_value)
              -- Unlock all levels
              ModSettingSet("kaleva_koetus.ascension_highest", "20")
              reset_ascension_level()

              print("[Kaleva Koetus] All ascensions unlocked!")
            end,
          },
        },
      },
    },
  },
}
