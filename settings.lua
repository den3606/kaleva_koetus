dofile_once("data/scripts/lib/mod_settings.lua")

-- Define mod_id for settings
local mod_id = "kaleva_koetus"

-- Build ascension level options for settings dropdown
local function get_ascension_values()
  local values = {
    { "disabled", "Disabled" },
  }

  local max_level = ModSettingGet("kaleva_koetus.ascension_highest") or 1
  -- Add unlocked ascension levels
  for i = 1, math.max(max_level, 1) do -- Show at least level 1 for testing
    table.insert(values, {
      "ascension_" .. i,
      "Ascension " .. i,
    })
  end

  return values
end

-- This function is called when the game is initializing settings
function ModSettingsUpdate(init_scope)
  local old_version = mod_settings_get_version(mod_id)
  mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the current value of the setting
function ModSettingsGuiCount()
  return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called when drawing the settings UI
function ModSettingsGui(gui, in_main_menu)
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
        id = "ascension_level",
        ui_name = "Ascension Level",
        ui_description = "Select the ascension level for this run",
        value_default = "disabled",
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
            id = "lock_all",
            ui_name = "Lock All Ascensions",
            ui_description = "Instantly lock all ascension levels (for testing)",
            value_default = "Click to lock ascension",
            values = { { "ok", "OK" } },
            scope = MOD_SETTING_SCOPE_RUNTIME,
            change_fn = function(mod_id, gui, in_main_menu, setting, old_value, new_value)
              -- Unlock all levels
              ModSettingSet("kaleva_koetus.ascension_highest", "1")

              print("[Kaleva Koetus] All ascensions locked!")

              -- Reset the checkbox
              ModSettingSetNextValue("kaleva_koetus.unlock_all", "ok", false)
            end,
          },
          {
            id = "unlock_all",
            ui_name = "Unlock All Ascensions",
            ui_description = "Instantly unlock all ascension levels (for testing)",
            value_default = "Click to unlock ascension",
            values = { { "ok", "OK" } },
            scope = MOD_SETTING_SCOPE_RUNTIME,
            change_fn = function(mod_id, gui, in_main_menu, setting, old_value, new_value)
              -- Unlock all levels
              ModSettingSet("kaleva_koetus.ascension_highest", "20")

              print("[Kaleva Koetus] All ascensions unlocked!")

              -- Reset the checkbox
              ModSettingSetNextValue("kaleva_koetus.unlock_all", "ok", false)
            end,
          },
        },
      },
    },
  },
}
