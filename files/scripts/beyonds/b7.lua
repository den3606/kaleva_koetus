---@type nxml
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
---@type common_csv
local common_csv = dofile_once("mods/kaleva_koetus/files/scripts/lib/noita_common_csv/common_csv.lua")

local reduce_potion = dofile_once("mods/kaleva_koetus/files/scripts/items/reduce_potion_capacity.lua")
local MATERIAL_SCALE = 0.5

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("b7.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 7
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

function beyond:on_mod_init()
  -- log:info("Potion volume reduced to %.0f%%", MATERIAL_SCALE * 100)
  for content in nxml.edit_file("data/entities/items/pickup/potion_aggressive.xml") do
    content:create_child("LuaComponent", {
      execute_every_n_frame = "-1",
      remove_after_executed = "1",
      script_item_picked_up = "mods/kaleva_koetus/files/scripts/appends/potion_aggressive_pick_up_b7.lua",
    })
  end

  ModLuaFileAppend("data/scripts/items/potion.lua", "mods/kaleva_koetus/files/scripts/appends/potion_b7.lua")
  ModLuaFileAppend("data/scripts/items/powder_stash.lua", "mods/kaleva_koetus/files/scripts/appends/potion_b7.lua")
  ModLuaFileAppend("data/scripts/items/potion_secret.lua", "mods/kaleva_koetus/files/scripts/appends/potion_secret_b7.lua")
  ModLuaFileAppend("data/scripts/items/potion_aggressive.lua", "mods/kaleva_koetus/files/scripts/appends/potion_aggressive_b7.lua")

  ModLuaFileAppend("data/scripts/status_effects/status_list.lua", "mods/kaleva_koetus/files/scripts/appends/status_list_b7.lua")
end

---@param elem element
---@param change_func fun(old_chance: number): number
local function change_drop_chance(elem, change_func)
  local liquid_sprite_stain_shaken_drop_chance = elem:get("liquid_sprite_stain_shaken_drop_chance")
  if liquid_sprite_stain_shaken_drop_chance then
    local old_chance = tonumber(liquid_sprite_stain_shaken_drop_chance) or 0
    elem:set("liquid_sprite_stain_shaken_drop_chance", tostring(change_func(old_chance)))
  end
end

---@param elem element
---@param change_func fun(type:string, old_amount: number): number
local function change_ingestion_status_amount(elem, change_func)
  local status_effects = elem:first_of("StatusEffects")
  if status_effects then
    local ingestion = status_effects:first_of("Ingestion")
    if ingestion then
      for _, status_effect in ipairs(ingestion:all_of("StatusEffect")) do
        local type = status_effect:get("type") or ""
        local old_amount = status_effect:get("amount")
        local old_amount_num = old_amount and tonumber(old_amount) or 0
        status_effect:set("amount", tostring(change_func(type, old_amount_num)))
      end
    end
  end
end

---@param elem element
---@param from_effect string
---@param to_effect string
local function change_effects(elem, from_effect, to_effect)
  if elem:get("status_effects") == from_effect then
    elem:set("status_effects", to_effect)
  end
  local status_effects = elem:first_of("StatusEffects")
  if status_effects then
    local stains = status_effects:first_of("Stains")
    if stains then
      for _, status_effect in ipairs(stains:all_of("StatusEffect")) do
        if status_effect:get("type") == from_effect then
          status_effect:set("type", to_effect)
        end
      end
    end
    local ingestion = status_effects:first_of("Ingestion")
    if ingestion then
      for _, status_effect in ipairs(ingestion:all_of("StatusEffect")) do
        if status_effect:get("type") == from_effect then
          status_effect:set("type", to_effect)
        end
      end
    end
  end
end

function beyond:on_mod_post_init()
  local common_text = ModTextFileGetContent("data/translations/common.csv")
  local parsed_common = common_csv.parse(common_text)

  local common_add = {}
  local language_list, min_columns = parsed_common:parse_header()

  local prefixes = {}
  local incomplete_prefixes = parsed_common:query("kaleva_koetus_incomplete_prefix")
  incomplete_prefixes = incomplete_prefixes or { "Incomplete " }
  for index, _ in ipairs(language_list) do
    prefixes[index] = incomplete_prefixes[index] or incomplete_prefixes[1]
  end
  local ui_name_keys = {
    "status_movement_faster",
    "status_protection_all",
    "status_teleportation",
  }
  for _, ui_name_key in ipairs(ui_name_keys) do
    local ui_names = parsed_common:query(ui_name_key)
    local extended_translation_line = { "kaleva_koetus_b7_" .. ui_name_key }
    for index, prefix in ipairs(prefixes) do
      table.insert(extended_translation_line, prefix .. (ui_names and (ui_names[index] or ui_names[1]) or ui_name_key))
    end
    table.insert(common_add, extended_translation_line)
  end

  local ui_description_keys = {
    "statusdesc_movement_faster",
    "statusdesc_protection_all",
    "statusdesc_teleportation",
  }
  for _, ui_description_key in ipairs(ui_description_keys) do
    local ui_descriptions = parsed_common:query(ui_description_key)
    local statusdesc_appends = parsed_common:query("kaleva_koetus_b7_" .. ui_description_key .. "_append")

    local extended_translation_line = { "kaleva_koetus_b7_" .. ui_description_key }
    for index, _ in ipairs(language_list) do
      local base = ui_descriptions and ui_descriptions[index] or ui_description_key
      local append = statusdesc_appends and (statusdesc_appends[index] or statusdesc_appends[1])
      if append ~= nil then
        table.insert(extended_translation_line, base .. "\\n" .. append)
      else
        table.insert(extended_translation_line, base)
      end
    end
    table.insert(common_add, extended_translation_line)
  end

  parsed_common:append(common_add, min_columns)
  ModTextFileSetContent("data/translations/common.csv", tostring(parsed_common))

  local ui_icons = {
    "data/ui_gfx/status_indicators/movement_faster.png",
    "data/ui_gfx/status_indicators/protection_all.png",
    "data/ui_gfx/status_indicators/teleportation.png",
  }
  for _, ui_icon in ipairs(ui_icons) do
    local id, x, y = ModImageMakeEditable(ui_icon, 0, 0)
    local id2, _, _ = ModImageMakeEditable("mods/kaleva_koetus/b7/" .. ui_icon, x, y)
    for i = 0, x - 1, 1 do
      for j = 0, y - 1, 1 do
        local color = ModImageGetPixel(id, i, j)
        local inverted = ImageEditor:invert_hue_abgr(color)
        ModImageSetPixel(id2, i, j, inverted)
      end
    end
  end

  for content in nxml.edit_file("data/materials.xml") do
    local elem_names = {
      "CellData",
      "CellDataChild",
    }
    for _, elem_name in ipairs(elem_names) do
      for _, elem in ipairs(content:all_of(elem_name)) do
        local attr_name = elem:get("name")
        if attr_name == "magic_liquid_movement_faster" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 3, 10)
            end
            return old_chance
          end)
          change_ingestion_status_amount(elem, function(type, old_amount)
            if type == "MOVEMENT_FASTER_2X" then
              old_amount = old_amount * 0.25
            end
            return old_amount
          end)
          change_effects(elem, "MOVEMENT_FASTER_2X", "INCOMPLETE_MOVEMENT_FASTER_2X")
        elseif attr_name == "magic_liquid_faster_levitation" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 3, 10)
            end
            return old_chance
          end)
          change_ingestion_status_amount(elem, function(type, old_amount)
            if type == "FASTER_LEVITATION" then
              old_amount = old_amount * 0.25
            end
            return old_amount
          end)
        elseif attr_name == "magic_liquid_faster_levitation_and_movement" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 3, 10)
            end
            return old_chance
          end)
          change_ingestion_status_amount(elem, function(type, old_amount)
            if type == "MOVEMENT_FASTER_2X" or type == "FASTER_LEVITATION" then
              old_amount = old_amount * 0.25
            end
            return old_amount
          end)
          change_effects(elem, "MOVEMENT_FASTER_2X", "INCOMPLETE_MOVEMENT_FASTER_2X")
        elseif attr_name == "magic_liquid_protection_all" then
          change_effects(elem, "PROTECTION_ALL", "INCOMPLETE_PROTECTION_ALL")
        elseif attr_name == "magic_liquid_mana_regeneration" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 2, 10)
            end
            return old_chance
          end)
          change_ingestion_status_amount(elem, function(type, old_amount)
            if type == "MANA_REGENERATION" then
              old_amount = old_amount * 0.25
            end
            return old_amount
          end)
        elseif attr_name == "magic_liquid_unstable_teleportation" then
          change_effects(elem, "UNSTABLE_TELEPORTATION", "INCOMPLETE_UNSTABLE_TELEPORTATION")
        elseif attr_name == "magic_liquid_teleportation" then
          change_effects(elem, "TELEPORTATION", "INCOMPLETE_TELEPORTATION")
        elseif attr_name == "magic_liquid_berserk" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 5, 10)
            end
            return old_chance
          end)
          change_ingestion_status_amount(elem, function(type, old_amount)
            if type == "BERSERK" then
              old_amount = old_amount * 0.25
            end
            return old_amount
          end)
        elseif attr_name == "magic_liquid_charm" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(math.max(old_chance * 3, 3), 10)
            end
            return old_chance
          end)
        elseif attr_name == "magic_liquid_invisibility" then
          change_drop_chance(elem, function(old_chance)
            if old_chance < 10 then
              old_chance = math.min(old_chance * 5, 10)
            end
            return old_chance
          end)
        end
      end
    end
  end
end

function beyond:on_potion_generated(entity_id)
  reduce_potion(entity_id, MATERIAL_SCALE)
end

return beyond
