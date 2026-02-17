---@type nxml
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
---@type common_csv
local common_csv = dofile_once("mods/kaleva_koetus/files/scripts/lib/noita_common_csv/common_csv.lua")
---@type path32
local path32 = dofile_once("mods/kaleva_koetus/files/scripts/lib/path32.lua")

---@type ImageEditor
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

---@type PerkUtils
local PerkUtils = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_perk_utils.lua")
local get_tagged_game_effect_count = PerkUtils.get_tagged_game_effect_count
local get_perk_pickup_count = PerkUtils.get_perk_pickup_count

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local LevelTags = EventDefs.Tags
local EventTypes = EventDefs.Types

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 9
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

-- local log = Logger:new("b9.lua")

local REDUCE_PERK_COUNT = 1
local MIN_PERK_COUNT = 2

local b9_reduce_perk_key = LevelTags.B9 .. "perk_reduced"
local b9_enemy_tag = LevelTags.B9 .. EventTypes.ENEMY_POST_SPAWN

local AVERAGE_COST_REDUCE = 0.25

local function determine_target_perk_count()
  local default = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3")) or 3
  return math.max(MIN_PERK_COUNT, default - REDUCE_PERK_COUNT)
end

local function enforce_perk_count(target)
  GlobalsSetValue("TEMPLE_PERK_COUNT", tostring(target))
  GlobalsSetValue("kaleva_koetus_base_TEMPLE_PERK_COUNT", tostring(target))
end

function beyond:on_mod_init()
  ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/kaleva_koetus/files/scripts/appends/perk_b9.lua")

  ModLuaFileAppend("data/scripts/gun/procedural/gun_procedural.lua", "mods/kaleva_koetus/files/scripts/appends/gun_procedural_b9.lua")
  ModLuaFileAppend(
    "data/scripts/gun/procedural/gun_procedural_better.lua",
    "mods/kaleva_koetus/files/scripts/appends/gun_procedural_b9.lua"
  )

  ModLuaFileAppend("data/scripts/gun/gun_extra_modifiers.lua", "mods/kaleva_koetus/files/scripts/appends/gun_extra_modifiers_b9.lua")
  for content in nxml.edit_file("data/entities/items/pickup/potion_porridge.xml") do
    content:create_child("LifetimeComponent", {
      _tags = "enabled_in_world,enabled_in_hand,enabled_in_inventory",
      lifetime = "0",
    })
  end

  ModLuaFileAppend("data/scripts/items/gold_pickup.lua", "mods/kaleva_koetus/files/scripts/appends/gold_pickup_b9.lua")
end

function beyond:on_mod_post_init()
  local common_text = ModTextFileGetContent("data/translations/common.csv")
  local parsed_common = common_csv.parse(common_text)

  local common_add = {}
  local language_list, min_columns = parsed_common:parse_header()
  local language_count = #language_list

  local prefixes = {}
  local incomplete_prefixes = parsed_common:query("kaleva_koetus_incomplete_prefix")
  incomplete_prefixes = incomplete_prefixes or { "Incomplete " }
  for index = 1, language_count do
    prefixes[index] = incomplete_prefixes[index] or incomplete_prefixes[1]
  end

  local _ = dofile("data/scripts/perks/perk_list.lua")
  -- selene: allow(undefined_variable)
  local perk_list = perk_list
  ---@cast perk_list PerkData[]

  ---@param line string[]
  ---@param index number
  ---@return string
  local function safe_index(line, index)
    return line[index] or line[1] or ""
  end

  ---@param text string
  ---@return string
  local function process_text(text)
    local processed_text = string.gsub(text, '"+', function(match)
      if #match % 2 == 1 then
        return match .. '"'
      else
        return match
      end
    end)

    return processed_text
  end

  local special_id_map = {
    ["EXTRA_MONEY"] = "effect_reduced",
    ["EXTRA_HP"] = "effect_reduced",
    ["HEARTS_MORE_EXTRA_HP"] = "effect_reduced",
    ["PERKS_LOTTERY"] = "effect_reduced",
    ["PROJECTILE_HOMING_SHOOTER"] = "small_damage",
    ["RISKY_CRITICAL"] = "small_damage",
    ["LOWER_SPREAD"] = "small_damage",
    ["NO_MORE_SHUFFLE"] = "probability",
    ["EXTRA_PERK"] = "probability",
    ["EXPLODING_CORPSES"] = "protections",
    ["PROTECTION_FIRE"] = "protections",
    ["PROTECTION_EXPLOSION"] = "protections",
    ["PROTECTION_MELEE"] = "protections",
    ["PROTECTION_ELECTRICITY"] = "protections",
    ["FREEZE_FIELD"] = "protections",
    ["BLEED_OIL"] = "protections",
  }
  ---@param id string
  ---@return string
  local function get_description_append_key(id)
    id = special_id_map[id] or id
    return "kaleva_koetus_perkdesc_" .. id .. "_append"
  end

  ---@param id string
  ---@param key_or_text string
  ---@param description_appends string[]
  ---@return string[]
  local function get_appended_perkdesc_line(id, key_or_text, description_appends)
    local extended_translation_line = { "kaleva_koetus_perkdesc_" .. id }

    if string.sub(key_or_text, 1, 1) == "$" then
      local key = string.sub(key_or_text, 2)

      local ui_descriptions = parsed_common:query(key)
      if ui_descriptions == nil then
        for index = 1, language_count do
          extended_translation_line[index + 1] = safe_index(description_appends, index)
        end
      else
        for index = 1, language_count do
          local base = safe_index(ui_descriptions, index)
          local append = safe_index(description_appends, index)
          if base == "" then
            extended_translation_line[index + 1] = append
          else
            extended_translation_line[index + 1] = base .. "\\n" .. append
          end
        end
      end
    else
      if key_or_text == "" then
        for index = 1, language_count do
          extended_translation_line[index + 1] = safe_index(description_appends, index)
        end
      else
        local text = process_text(key_or_text)
        for index = 1, language_count do
          local append = safe_index(description_appends, index)
          extended_translation_line[index + 1] = text .. "\\n" .. append
        end
      end
    end

    return extended_translation_line
  end

  ---@param id string
  ---@param key_or_text string
  ---@return string[]
  local function get_appended_perk_line(id, key_or_text)
    local extended_translation_line = { "kaleva_koetus_perk_" .. id }

    if string.sub(key_or_text, 1, 1) == "$" then
      local key = string.sub(key_or_text, 2)

      local ui_names = parsed_common:query(key)
      if ui_names == nil then
        for index = 1, language_count do
          extended_translation_line[index + 1] = prefixes[index]
        end
      else
        for index = 1, language_count do
          extended_translation_line[index + 1] = process_text(prefixes[index] .. safe_index(ui_names, index))
        end
      end
    else
      for index = 1, language_count do
        extended_translation_line[index + 1] = process_text(prefixes[index] .. key_or_text)
      end
    end

    return extended_translation_line
  end

  ---@param raw_key string
  ---@param sep string
  ---@param ... string
  ---@return string[]
  local function get_concated_line(raw_key, sep, ...)
    local extended_translation_line = { raw_key }

    local key_or_text_list = { ... }
    local texts_list = {}
    for _, key_or_text in ipairs(key_or_text_list) do
      if string.sub(key_or_text, 1, 1) == "$" then
        local key = string.sub(key_or_text, 2)

        local texts = parsed_common:query(key)
        if texts ~= nil then
          table.insert(texts_list, texts)
        end
      else
        table.insert(texts_list, { key_or_text })
      end
    end

    for index = 1, language_count do
      local elems = {}
      for _, texts in ipairs(texts_list) do
        table.insert(elems, safe_index(texts, index))
      end
      extended_translation_line[index + 1] = process_text(table.concat(elems, sep))
    end

    return extended_translation_line
  end

  for _, perk_data in ipairs(perk_list) do
    local description_appends = parsed_common:query(get_description_append_key(perk_data.id))
    if description_appends ~= nil then
      local extended_translation_line = get_appended_perkdesc_line(perk_data.id, perk_data.ui_description, description_appends)
      table.insert(common_add, extended_translation_line)

      extended_translation_line = get_appended_perk_line(perk_data.id, perk_data.ui_name)
      table.insert(common_add, extended_translation_line)

      local encoded_perk_id = path32.encode(perk_data.id)
      local id, x, y = ModImageMakeEditable(perk_data.ui_icon, 0, 0)
      local id2, _, _ = ModImageMakeEditable("mods/kaleva_koetus/files/ui_gfx/perk_icons/" .. encoded_perk_id .. ".png", x, y)
      for i = 0, x - 1, 1 do
        for j = 0, y - 1, 1 do
          local color = ModImageGetPixel(id, i, j)
          local inverted = ImageEditor:invert_hue_abgr(color)
          ModImageSetPixel(id2, i, j, inverted)
        end
      end

      local perk_icon = perk_data.perk_icon or "data/items_gfx/perk.xml"
      if perk_icon:find(".png", -4, true) ~= nil then
        id, x, y = ModImageMakeEditable(perk_icon, 0, 0)
        id2, _, _ = ModImageMakeEditable("mods/kaleva_koetus/files/items_gfx/perks/" .. encoded_perk_id .. ".png", x, y)
        for i = 0, x - 1, 1 do
          for j = 0, y - 1, 1 do
            local color = ModImageGetPixel(id, i, j)
            local inverted = ImageEditor:invert_hue_abgr(color)
            ModImageSetPixel(id2, i, j, inverted)
          end
        end
      elseif perk_icon:find(".xml", -4, true) ~= nil then
        local elem = nxml.parse_file(perk_icon)
        local filename = elem:get("filename")
        if filename ~= nil then
          local new_filename = "mods/kaleva_koetus/files/items_gfx/perks/anims/" .. encoded_perk_id .. ".png"
          id, x, y = ModImageMakeEditable(filename, 0, 0)
          id2, _, _ = ModImageMakeEditable(new_filename, x, y)
          for i = 0, x - 1, 1 do
            for j = 0, y - 1, 1 do
              local color = ModImageGetPixel(id, i, j)
              local inverted = ImageEditor:invert_hue_abgr(color)
              ModImageSetPixel(id2, i, j, inverted)
            end
          end

          elem:set("filename", new_filename)
          ModTextFileSetContent("mods/kaleva_koetus/files/items_gfx/perks/anims/" .. encoded_perk_id .. ".xml", tostring(elem))
        end
      end
    end
  end

  for _, perk_data in ipairs(perk_list) do
    if perk_data.id == "SAVING_GRACE" then
      local id, x, y = ModImageMakeEditable(perk_data.ui_icon, 0, 0)
      local id2, _, _ = ModImageMakeEditable("mods/kaleva_koetus/files/ui_gfx/status_indicators/saving_grace_cooldown.png", x, y)
      for i = 0, x - 1, 1 do
        for j = 0, y - 1, 1 do
          local color = ModImageGetPixel(id, i, j)
          local gray = ImageEditor:grayscale_abgr(color)
          ModImageSetPixel(id2, i, j, gray)
        end
      end

      local extended_translation_line = get_concated_line(
        "kaleva_koetus_status_saving_grace_cooldown",
        "",
        perk_data.ui_name,
        "$kaleva_koetus_status_saving_grace_cooldown_append"
      )
      table.insert(common_add, extended_translation_line)

      extended_translation_line = get_concated_line(
        "kaleva_koetus_statusdesc_saving_grace_cooldown",
        "",
        "$kaleva_koetus_statusdesc_saving_grace_cooldown_prefix",
        perk_data.ui_description
      )
      table.insert(common_add, extended_translation_line)
    elseif perk_data.id == "RESPAWN" then
      local id, x, y = ModImageMakeEditable("data/ui_gfx/perk_icons/respawn_spent.png", 0, 0)
      local id2, _, _ =
        ModImageMakeEditable("mods/kaleva_koetus/files/ui_gfx/perk_icons/" .. path32.encode("RESPAWN_spent") .. ".png", x, y)
      for i = 0, x - 1, 1 do
        for j = 0, y - 1, 1 do
          local color = ModImageGetPixel(id, i, j)
          local inverted = ImageEditor:invert_hue_abgr(color)
          ModImageSetPixel(id2, i, j, inverted)
        end
      end

      local description_appends = parsed_common:query(get_description_append_key(perk_data.id))
      if description_appends ~= nil then
        local extended_translation_line = get_appended_perkdesc_line("RESPAWN_spent", "$perkdesc_respawn_spent", description_appends)
        table.insert(common_add, extended_translation_line)
      end

      local extended_translation_line = get_appended_perk_line("RESPAWN_spent", "$perk_respawn_spent")
      table.insert(common_add, extended_translation_line)
    end
  end

  parsed_common:append(common_add, min_columns)
  ModTextFileSetContent("data/translations/common.csv", tostring(parsed_common))

  ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/kaleva_koetus/files/scripts/appends/perk_list_b9.lua")
end

function beyond:on_world_initialized()
  if GlobalsGetValue(b9_reduce_perk_key, "0") == "1" then
    return
  end

  local target_perk_count = determine_target_perk_count()

  enforce_perk_count(target_perk_count)

  GlobalsSetValue(b9_reduce_perk_key, "1")
end

local invisible_enemies = false
function beyond:on_enemy_post_spawn(entity_id, _x, _y)
  if EntityHasTag(entity_id, b9_enemy_tag) == true then
    return
  end

  if invisible_enemies == true then
    local effect_component_id, _effect_entity_id = GetGameEffectLoadTo(entity_id, "INVISIBILITY", true)
    if effect_component_id ~= 0 then
      ComponentSetValue2(effect_component_id, "frames", -1)
    end
  end

  EntityAddTag(entity_id, b9_enemy_tag)
end

local function get_gun_ability_component(entity_id)
  local ability_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
  if ability_component_id == nil then
    return nil
  end

  return ComponentGetValue2(ability_component_id, "use_gun_script") and ability_component_id or nil
end

---@param entity_id number
---@return table<number, number>
local function collect_wand_edit_stats(entity_id)
  local wand_edit_times = {}

  local inventory_items = GameGetAllInventoryItems(entity_id)
  if inventory_items == nil then
    return wand_edit_times
  end

  for _, inventory_item in ipairs(inventory_items) do
    local ability_component_id = get_gun_ability_component(inventory_item)
    if ability_component_id ~= nil then
      wand_edit_times[inventory_item] = ComponentGetValue2(ability_component_id, "stat_times_player_has_edited")
    end
  end

  return wand_edit_times
end

---@param old_edit_times table<number, number>
---@param new_edit_times table<number, number>
---@return table<number, number>
local function diff_wand_edit_stats(old_edit_times, new_edit_times)
  local wand_edit_times_diff = {}

  for wand_entity_id, edit_times in pairs(new_edit_times) do
    local prev_edit_times = old_edit_times[wand_entity_id]
    if prev_edit_times ~= nil then
      local delta_edit_times = edit_times - prev_edit_times
      if delta_edit_times > 0 then
        wand_edit_times_diff[wand_entity_id] = delta_edit_times
      end
    end
  end

  return wand_edit_times_diff
end

---@param entity_id number
---@param hitbox_component_id number
---@return number
---@return number
---@return number
---@return number
---@overload fun(entity_id:number, hitbox_component_id:number)
local function get_hitbox_aabb(entity_id, hitbox_component_id)
  local x, y, _rotation, scale_x, scale_y = EntityGetTransform(entity_id)
  local offset_x, offset_y = ComponentGetValue2(hitbox_component_id, "offset")
  local x1 = x + ComponentGetValue2(hitbox_component_id, "aabb_min_x") + offset_x * scale_x
  local x2 = x + ComponentGetValue2(hitbox_component_id, "aabb_max_x") + offset_x * scale_x
  local y1 = y + ComponentGetValue2(hitbox_component_id, "aabb_min_y") + offset_y * scale_y
  local y2 = y + ComponentGetValue2(hitbox_component_id, "aabb_max_y") + offset_y * scale_y
  if x1 > x2 or y1 > y2 then
    return
  end
  return x1, x2, y1, y2
end

---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@param x3 number
---@param x4 number
---@param y3 number
---@param y4 number
---@return boolean
local function is_intersected(x1, x2, y1, y2, x3, x4, y3, y4)
  return x2 >= x3 and x1 <= x4 and y2 >= y3 and y1 <= y4
end

local function in_workshop(entity_id)
  local hitbox_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "HitboxComponent")
  if hitbox_component_id == nil then
    return false
  end
  local x1, x2, y1, y2 = get_hitbox_aabb(entity_id, hitbox_component_id)
  if x1 == nil then
    return false
  end

  local workshop_entities = EntityGetWithTag("workshop")
  for _, workshop_entity_id in ipairs(workshop_entities) do
    local workshop_hitbox_component_id = EntityGetFirstComponent(workshop_entity_id, "HitboxComponent")
    if workshop_hitbox_component_id ~= nil then
      local x3, x4, y3, y4 = get_hitbox_aabb(workshop_entity_id, workshop_hitbox_component_id)
      if x3 ~= nil then
        if is_intersected(x1, x2, y1, y2, x3, x4, y3, y4) then
          return true
        end
      end
    end
  end

  return false
end

---@class WandData
---@field mana number
---@field mana_max number
---@field mana_charge_speed number
---@field shuffle_deck_when_empty boolean
---@field reload_time number
---@field deck_capacity number
---@field fire_rate_wait number
---@field spread_degrees number
---@field always_cast_count number

---@param entity_id any
---@param ability_component_id any
---@return WandData
local function get_wand_data(entity_id, ability_component_id)
  local deck_capacity = EntityGetWandCapacity(entity_id)
  ---@type WandData
  local wand_data = {
    mana = ComponentGetValue2(ability_component_id, "mana"),
    mana_max = ComponentGetValue2(ability_component_id, "mana_max"),
    mana_charge_speed = ComponentGetValue2(ability_component_id, "mana_charge_speed"),
    shuffle_deck_when_empty = ComponentObjectGetValue2(ability_component_id, "gun_config", "shuffle_deck_when_empty"),
    reload_time = ComponentObjectGetValue2(ability_component_id, "gun_config", "reload_time"),
    deck_capacity = deck_capacity,
    fire_rate_wait = ComponentObjectGetValue2(ability_component_id, "gunaction_config", "fire_rate_wait"),
    spread_degrees = ComponentObjectGetValue2(ability_component_id, "gunaction_config", "spread_degrees"),
    always_cast_count = ComponentObjectGetValue2(ability_component_id, "gun_config", "deck_capacity") - deck_capacity,
  }
  return wand_data
end

local function is_action_card(entity_id)
  return EntityGetFirstComponentIncludingDisabled(entity_id, "ItemActionComponent") ~= nil
end

local function is_always_cast(entity_id)
  local item_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemComponent")
  if item_component_id == nil then
    return false
  end

  return ComponentGetValue2(item_component_id, "permanently_attached")
end

---@param entity_id number
---@param ability_component_id number
---@param wand_data WandData
---@param old_wand_data WandData?
---@return boolean changed
local function set_wand_data(entity_id, ability_component_id, wand_data, old_wand_data)
  local change_any = false

  old_wand_data = old_wand_data or get_wand_data(entity_id, ability_component_id)

  if wand_data.mana_max ~= old_wand_data.mana_max then
    ComponentSetValue2(ability_component_id, "mana_max", wand_data.mana_max)
    ComponentSetValue2(ability_component_id, "mana", math.min(old_wand_data.mana, wand_data.mana_max))
    change_any = true
  end
  if wand_data.mana_charge_speed ~= old_wand_data.mana_charge_speed then
    ComponentSetValue2(ability_component_id, "mana_charge_speed", wand_data.mana_charge_speed)
    change_any = true
  end
  if wand_data.reload_time ~= old_wand_data.reload_time then
    ComponentObjectSetValue2(ability_component_id, "gun_config", "reload_time", wand_data.reload_time)
    change_any = true
  end
  if wand_data.deck_capacity ~= old_wand_data.deck_capacity then
    ComponentObjectSetValue2(ability_component_id, "gun_config", "deck_capacity", wand_data.deck_capacity + old_wand_data.always_cast_count)
    local child_entities = EntityGetAllChildren(entity_id)
    if child_entities ~= nil then
      local x, y = EntityGetTransform(entity_id)
      local action_card_count = 0
      for _, child_entity_id in ipairs(child_entities) do
        if is_action_card(child_entity_id) and not is_always_cast(child_entity_id) then
          if action_card_count >= wand_data.deck_capacity then
            local components = EntityGetAllComponents(child_entity_id)
            for _, component_id in ipairs(components) do
              if ComponentGetIsEnabled(component_id) and not ComponentHasTag(component_id, "enabled_in_world") then
                EntitySetComponentIsEnabled(child_entity_id, component_id, false)
              end
            end
            EntityRemoveFromParent(child_entity_id)
            EntitySetTransform(child_entity_id, x, y)
            EntitySetComponentsWithTagEnabled(child_entity_id, "enabled_in_world", true)
          else
            action_card_count = action_card_count + 1
          end
        end
      end
    end
    change_any = true
  end
  if wand_data.fire_rate_wait ~= old_wand_data.fire_rate_wait then
    ComponentObjectSetValue2(ability_component_id, "gunaction_config", "fire_rate_wait", wand_data.fire_rate_wait)
    change_any = true
  end
  if wand_data.spread_degrees ~= old_wand_data.spread_degrees then
    ComponentObjectSetValue2(ability_component_id, "gunaction_config", "spread_degrees", wand_data.fire_rate_wait)
    change_any = true
  end

  return change_any
end

---@class WandModifier
---@field cost fun(wand_data: WandData): number
---@field max_repeat fun(wand_data: WandData): number
---@field apply fun(wand_data: WandData, repeat_times:number)
---@field format fun(old_wand_data: WandData, new_wand_data: WandData): string?

---@type WandModifier[]
local wand_modifiers = {
  {
    cost = function(_wand_data)
      return 0.0625
    end,
    max_repeat = function(wand_data)
      local min = 50
      return math.max(wand_data.mana_max - min, 0)
    end,
    apply = function(wand_data, repeat_times)
      local min = 50
      if wand_data.mana_max > min then
        wand_data.mana_max = math.max(wand_data.mana_max - repeat_times, min)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.mana_max == old_wand_data.mana_max then
        return
      end
      local from = tostring(old_wand_data.mana_max)
      local to = tostring(new_wand_data.mana_max)
      return GameTextGet("$inventory_manamax") .. ": " .. from .. "->" .. to
    end,
  },
  {
    cost = function(_wand_data)
      return 0.2
    end,
    max_repeat = function(wand_data)
      local min = 10
      return math.max(wand_data.mana_charge_speed - min, 0)
    end,
    apply = function(wand_data, repeat_times)
      local min = 10
      if wand_data.mana_charge_speed > min then
        wand_data.mana_charge_speed = math.max(wand_data.mana_charge_speed - repeat_times, min)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.mana_charge_speed == old_wand_data.mana_charge_speed then
        return
      end
      local from = tostring(old_wand_data.mana_charge_speed)
      local to = tostring(new_wand_data.mana_charge_speed)
      return GameTextGet("$inventory_manachargespeed") .. ": " .. from .. "->" .. to
    end,
  },
  {
    cost = function(wand_data)
      return wand_data.shuffle_deck_when_empty and 5 or 10
    end,
    max_repeat = function(wand_data)
      local min = 2
      return math.max(wand_data.deck_capacity - min, 0)
    end,
    apply = function(wand_data, repeat_times)
      local min = 2
      if wand_data.deck_capacity > min then
        wand_data.deck_capacity = math.max(wand_data.deck_capacity - repeat_times, min)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.deck_capacity == old_wand_data.deck_capacity then
        return
      end
      local from = tostring(old_wand_data.deck_capacity)
      local to = tostring(new_wand_data.deck_capacity)
      return GameTextGet("$inventory_capacity") .. ": " .. from .. "->" .. to
    end,
  },
  {
    cost = function(_wand_data)
      return 0.2
    end,
    max_repeat = function(wand_data)
      local max = 240
      return math.max(max - wand_data.reload_time, 0)
    end,
    apply = function(wand_data, repeat_times)
      local max = 240
      if wand_data.reload_time < max then
        wand_data.reload_time = math.min(wand_data.reload_time + repeat_times, max)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.reload_time == old_wand_data.reload_time then
        return
      end
      local from = GameTextGet("$inventory_seconds", string.format("%.2f", old_wand_data.reload_time / 60))
      local to = GameTextGet("$inventory_seconds", string.format("%.2f", new_wand_data.reload_time / 60))
      return GameTextGet("$inventory_rechargetime") .. ": " .. from .. "->" .. to
    end,
  },
  {
    cost = function(_wand_data)
      return 1
    end,
    max_repeat = function(wand_data)
      local max = 50
      return math.max(max - wand_data.fire_rate_wait, 0)
    end,
    apply = function(wand_data, repeat_times)
      local max = 50
      if wand_data.fire_rate_wait < max then
        wand_data.fire_rate_wait = math.min(wand_data.fire_rate_wait + repeat_times, max)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.fire_rate_wait == old_wand_data.fire_rate_wait then
        return
      end
      local from = GameTextGet("$inventory_seconds", string.format("%.2f", old_wand_data.fire_rate_wait / 60))
      local to = GameTextGet("$inventory_seconds", string.format("%.2f", new_wand_data.fire_rate_wait / 60))
      return GameTextGet("$inventory_castdelay") .. ": " .. from .. "->" .. to
    end,
  },
  {
    cost = function(_wand_data)
      return 1
    end,
    max_repeat = function(wand_data)
      local max = 35
      return math.max(max - wand_data.spread_degrees, 0)
    end,
    apply = function(wand_data, repeat_times)
      local max = 35
      if wand_data.spread_degrees < max then
        wand_data.spread_degrees = math.min(wand_data.spread_degrees + repeat_times, max)
      end
    end,
    format = function(old_wand_data, new_wand_data)
      if new_wand_data.spread_degrees == old_wand_data.spread_degrees then
        return
      end
      local from = GameTextGet("$inventory_degrees", string.format("%.1f", old_wand_data.spread_degrees))
      local to = GameTextGet("$inventory_degrees", string.format("%.1f", new_wand_data.spread_degrees))
      return GameTextGet("$inventory_spread") .. ": " .. from .. "->" .. to
    end,
  },
}

---@param entity_id number
---@param edit_times number
---@return boolean changed
local function wear_wand(entity_id, edit_times)
  local total_cost = AVERAGE_COST_REDUCE * edit_times

  local ability_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
  if ability_component_id == nil then
    return false
  end

  local wand_data = get_wand_data(entity_id, ability_component_id)

  local selected_modifiers = {}
  for _, modifier in ipairs(wand_modifiers) do
    local max_repeat = modifier.max_repeat(wand_data)
    if max_repeat > 0 then
      local mean = total_cost / modifier.cost(wand_data)
      if max_repeat <= mean then
        table.insert(selected_modifiers, {
          mean = max_repeat,
          range = 0,
          apply = modifier.apply,
          format = modifier.format,
        })
      else
        table.insert(selected_modifiers, {
          mean = mean,
          range = math.min(mean * 0.5, max_repeat - mean),
          apply = modifier.apply,
          format = modifier.format,
        })
      end
    end
  end

  SetRandomSeed(GameGetFrameNum(), entity_id)

  local selected_modifier = selected_modifiers[Random(1, #selected_modifiers)]

  local repeat_times
  if selected_modifier.range == 0 then
    repeat_times = selected_modifier.mean
  else
    local min = selected_modifier.mean - selected_modifier.range
    local max = selected_modifier.mean + selected_modifier.range
    local mean = selected_modifier.mean
    repeat_times = RandomDistributionf(min, max, mean, 2)
    repeat_times = math.floor(repeat_times + Random())
  end

  if repeat_times > 0 then
    selected_modifier.apply(wand_data, repeat_times)

    local old_wand_data = get_wand_data(entity_id, ability_component_id)
    local message = selected_modifier.format(old_wand_data, wand_data)

    if message ~= nil then
      GamePrint(message)
    end

    return set_wand_data(entity_id, ability_component_id, wand_data, old_wand_data)
  end

  return false
end

---@type table<number, number>
local latest_wand_edit_stats = {}
function beyond:on_world_pre_update()
  local player = EntityGetWithTag("player_unit")[1]
  if player == nil then
    return
  end

  local remove_fog_or_war_count = GameGetGameEffectCount(player, "REMOVE_FOG_OF_WAR")
  if remove_fog_or_war_count > 0 then
    local perk_effect_entity_count = get_tagged_game_effect_count(player, "REMOVE_FOG_OF_WAR", "kaleva_koetus_remove_fog_of_war")
    if perk_effect_entity_count < remove_fog_or_war_count then
      invisible_enemies = false
    else
      local perk_pickup_count = get_perk_pickup_count(player, "REMOVE_FOG_OF_WAR")
      invisible_enemies = perk_pickup_count < 2
    end
  else
    invisible_enemies = false
  end

  local now_wand_edit_stats = collect_wand_edit_stats(player)

  local changed_any = false

  local edit_level = 0
  if in_workshop(player) == true then
    edit_level = edit_level + 1
  end
  edit_level = edit_level - GameGetGameEffectCount(player, "NO_WAND_EDITING")
  if edit_level <= 0 then
    edit_level = edit_level + GameGetGameEffectCount(player, "EDIT_WANDS_EVERYWHERE")
    if edit_level > 0 then
      local perk_effect_entity_count = get_tagged_game_effect_count(player, "EDIT_WANDS_EVERYWHERE", "kaleva_koetus_edit_wands_everywhere")
      if edit_level - perk_effect_entity_count <= 0 then
        local perk_pickup_count = get_perk_pickup_count(player, "EDIT_WANDS_EVERYWHERE")
        if perk_pickup_count < 2 then
          local wand_edit_records = diff_wand_edit_stats(latest_wand_edit_stats, now_wand_edit_stats)
          for wand_entity_id, edit_times in pairs(wand_edit_records) do
            local changed = wear_wand(wand_entity_id, edit_times)
            changed_any = changed_any and changed
          end
        end
      end
    end
  end

  if changed_any == true then
    local inventory2_comp = EntityGetFirstComponent(player, "Inventory2Component")
    if inventory2_comp then
      ComponentSetValue2(inventory2_comp, "mActualActiveItem", 0)
    end
  end

  latest_wand_edit_stats = now_wand_edit_stats
end

return beyond
