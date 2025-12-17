local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
local nxml_helper = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/nxml_helper.lua")
---@type common_csv
local common_csv = dofile_once("mods/kaleva_koetus/files/scripts/lib/noita_common_csv/common_csv.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
-- local log = Logger:new("a15.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 15
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A15 .. EventTypes.SPELL_GENERATED

function ascension:on_activate()
  -- log:info("Broken spells")
end

local function parse_ui_name(elem)
  local ability_component = elem:first_of("AbilityComponent")
  if ability_component == nil then
    return nil
  end
  return ability_component:get("ui_name") or "[NOT_SET]"
end

local function parse_name(elem)
  return elem:get("name")
end

local XML_ENTITY_WRAPPER = [[<Entity>
%s
</Entity>
]]
local XML_ENTITY_WRAPPER_WITH_NAME = [[<Entity name="%s">
%s
</Entity>
]]
local XML_BASE_WRAPPER = [[  <Base file="%s" include_children="1" />]]
local XML_BASE_WRAPPER_CHANGE_UI_NAME = [[  <Base file="%s" include_children="1">
    <AbilityComponent
      ui_name="%s">
    </AbilityComponent>
  </Base>]]
local function get_file_content_ui_name_overrided(filename, ui_name, entity_name)
  local base_elem
  if ui_name == nil then
    base_elem = string.format(XML_BASE_WRAPPER, filename)
  else
    base_elem = string.format(XML_BASE_WRAPPER_CHANGE_UI_NAME, filename, ui_name)
  end
  if entity_name == nil then
    return string.format(XML_ENTITY_WRAPPER, base_elem)
  else
    return string.format(XML_ENTITY_WRAPPER_WITH_NAME, entity_name, base_elem)
  end
end

function ascension:on_mod_post_init()
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

  local key_to_extended_key = {}
  local function get_extended_translation_line(translation_key, text_or_key, fallback_text)
    local extended_translation_line = { translation_key }
    if string.sub(text_or_key, 1, 1) == "$" then
      local key = string.sub(text_or_key, 2)
      local translations = parsed_common:query(key)
      if translations ~= nil then
        key_to_extended_key[key] = translation_key
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
          extended_translation_line[col + 1] = prefix .. base_translation
        end
      else
        for col, prefix in ipairs(prefixes) do
          extended_translation_line[col + 1] = prefix .. fallback_text
        end
      end
    else
      for col, prefix in ipairs(prefixes) do
        extended_translation_line[col + 1] = prefix
          .. string.gsub(text_or_key, '"+', function(match)
            if #match % 2 == 1 then
              return match .. '"'
            else
              return match
            end
          end)
      end
    end
    return extended_translation_line
  end

  local function get_extended_key(text_or_key)
    if string.sub(text_or_key, 1, 1) == "$" then
      local key = string.sub(text_or_key, 2)
      return key_to_extended_key[key]
    end
    return nil
  end

  local common_add = {}

  local error_tracker = nxml_helper.create_tracker_ignoring({ "duplicate_attribute" })

  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions

  for _, action in ipairs(actions) do
    local id, x, y = ModImageMakeEditable(action.sprite, 0, 0)
    local id2, _, _ = ModImageMakeEditable("mods/kaleva_koetus/a15/sprites/" .. action.sprite, x, y)
    for i = 0, x - 1, 1 do
      for j = 0, y - 1, 1 do
        local color = ModImageGetPixel(id, i, j)
        local inverted = ImageEditor:invert_hue_abgr(color)
        ModImageSetPixel(id2, i, j, inverted)
      end
    end

    local extended_translation_line = get_extended_translation_line("kaleva_koetus_a15_action_" .. action.id, action.name, action.id)
    table.insert(common_add, extended_translation_line)

    local custom_xml_file = action.custom_xml_file
    if custom_xml_file ~= nil then
      local elem = nxml_helper.use_error_handler(nxml, error_tracker.error_handler, function()
        local parsed_elem = nxml.parse_file(custom_xml_file)
        parsed_elem:expand_base()
        return parsed_elem
      end)

      local ui_name = parse_ui_name(elem)
      if ui_name ~= nil then
        local extended_key = get_extended_key(ui_name)
        if extended_key == nil then
          extended_key = "kaleva_koetus_a15_card_action_" .. action.id
          extended_translation_line = get_extended_translation_line(extended_key, ui_name, action.id)
          table.insert(common_add, extended_translation_line)
        end
        ModTextFileSetContent(
          "mods/kaleva_koetus/a15/custom_cards/" .. custom_xml_file,
          get_file_content_ui_name_overrided(custom_xml_file, "$" .. extended_key, parse_name(elem))
        )
      else
        ModTextFileSetContent(
          "mods/kaleva_koetus/a15/custom_cards/" .. custom_xml_file,
          get_file_content_ui_name_overrided(custom_xml_file, nil, parse_name(elem))
        )
      end
    end
  end
  parsed_common:append(common_add, min_columns)
  ModTextFileSetContent("data/translations/common.csv", tostring(parsed_common))

  ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/kaleva_koetus/files/scripts/appends/gun_actions.lua")
end

return ascension
