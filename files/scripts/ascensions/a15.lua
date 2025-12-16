---@type common_csv
local common_csv = dofile_once("mods/kaleva_koetus/files/scripts/lib/noita_common_csv/common_csv.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local RandomUtils = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a15_random_utils.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
-- local log = Logger:new("a15.lua")

local ascension = setmetatable({}, { __index = AscensionBase })
local UNCOMPLETED_MULTIPLIER = RandomUtils.UNCOMPLETED_MULTIPLIER

ascension.level = 15
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A15 .. EventTypes.SPELL_GENERATED

function ascension:on_activate()
  -- log:info("Broken spells")
end

function ascension:on_mod_post_init()
  RandomUtils.init_root_seed()
  local actions_seed = RandomUtils.derive_seed("gun_actions")
  math.randomseed(actions_seed)

  local translated_prefixes = {
    ["en"] = "Incomplete ",
    ["ru"] = "Неполное ",
    ["pt-br"] = "Incompleto ",
    ["es-es"] = "Incompleto ",
    ["de"] = "Unvollständig ",
    ["fr-fr"] = "Incomplet ",
    ["it"] = "Incompleto ",
    ["pl"] = "Niekompletne ",
    ["zh-cn"] = "未完成的",
    ["jp"] = "未完成の",
    ["ko"] = "불완전한",
  }
  local common_text = ModTextFileGetContent("data/translations/common.csv")
  local parsed_common = common_csv.parse(common_text)

  local prefixes = {}
  local language_list, min_columns = parsed_common:parse_header()
  for index, language in ipairs(language_list) do
    prefixes[index] = translated_prefixes[language] or translated_prefixes["en"]
  end

  local common_add = {}

  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions

  local target_indexes = RandomUtils.random_unique_integers(1, #actions, math.floor(#actions * UNCOMPLETED_MULTIPLIER))
  for _, index in ipairs(target_indexes) do
    if actions[index].id ~= "MANA_REDUCE" then
      local id, x, y = ModImageMakeEditable(actions[index].sprite, 0, 0)
      for i = 0, x, 1 do
        for j = 0, y, 1 do
          local color = ModImageGetPixel(id, i, j)
          local inverted = ImageEditor:invert_hue_abgr(color)
          ModImageSetPixel(id, i, j, inverted)
        end
      end

      local name = actions[index].name
      local extended_translations
      if name ~= nil and string.sub(name, 1, 1) == "$" then
        local key = string.sub(name, 2)
        local translations = parsed_common:query(key)
        extended_translations = { "kaleva_koetus_a15_" .. key }
        if translations ~= nil then
          local column_count = #translations
          for col, prefix in ipairs(prefixes) do
            local base_translation
            if col <= column_count then
              base_translation = translations[col]
              if base_translation == "" then
                base_translation = translations[1]
              end
            else
              base_translation = translations[1]
            end
            extended_translations[col + 1] = prefix .. base_translation
          end
        else
          for col, prefix in ipairs(prefixes) do
            extended_translations[col + 1] = prefix .. actions[index].id
          end
        end
      else
        extended_translations = { "kaleva_koetus_a15_" .. actions[index].id }
        for col, prefix in ipairs(prefixes) do
          extended_translations[col + 1] = prefix
            .. string.gsub(name, '"+', function(match)
              if #match % 2 == 1 then
                return match .. '"'
              else
                return match
              end
            end)
        end
      end
      table.insert(common_add, extended_translations)
    end
  end
  parsed_common:append(common_add, min_columns)
  ModTextFileSetContent("data/translations/common.csv", tostring(parsed_common))

  ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/kaleva_koetus/files/scripts/appends/gun_actions.lua")
end

return ascension
