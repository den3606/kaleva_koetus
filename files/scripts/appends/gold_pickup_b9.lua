---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag

---@type PerkUtils
local PerkUtils = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_perk_utils.lua")
local get_tagged_game_effect_count = PerkUtils.get_tagged_game_effect_count

local function modify_gold_values(entity_item, entity_who_picked)
  local variable_storage_components = EntityGetComponent(entity_item, "VariableStorageComponent")
  if variable_storage_components == nil then
    return
  end

  local gold_storage_component_id
  local hp_storage_component_id
  for _, variable_storage_component_id in ipairs(variable_storage_components) do
    local name = ComponentGetValue2(variable_storage_component_id, "name")
    if name == "gold_value" then
      gold_storage_component_id = variable_storage_component_id
    elseif name == "hp_value" then
      hp_storage_component_id = variable_storage_component_id
    end
  end

  if gold_storage_component_id == nil and hp_storage_component_id == nil then
    return
  end

  local gold_value_multiplier = 1
  local hp_value_multiplier = 1

  local perk_extra_money_count = get_tagged_game_effect_count(entity_who_picked, "EXTRA_MONEY", "kaleva_koetus_extra_money")
  if perk_extra_money_count > 0 then
    gold_value_multiplier = gold_value_multiplier * 0.75 ^ perk_extra_money_count
  end

  if hp_storage_component_id ~= nil then
    if entity_has_variable_tag(entity_who_picked, "kaleva_koetus_trick_blood_money") then
      gold_value_multiplier = gold_value_multiplier * 0.6
      hp_value_multiplier = hp_value_multiplier * 0.2
    end

    local hp_value = ComponentGetValue2(hp_storage_component_id, "value_float")
    hp_value = hp_value * hp_value_multiplier
    ComponentSetValue2(hp_storage_component_id, "value_float", hp_value)
  end

  if gold_storage_component_id ~= nil then
    local gold_value = ComponentGetValue2(gold_storage_component_id, "value_int")
    if gold_value > 1 and gold_value < (2147483647 - 512) then
      gold_value = math.floor(gold_value * gold_value_multiplier + 0.5)
      gold_value = math.max(gold_value, 1)
      ComponentSetValue2(gold_storage_component_id, "value_int", gold_value)
    end
  end
end

-- selene: allow(undefined_variable)
local _item_pickup = item_pickup
-- selene: allow(unused_variable)
function item_pickup(entity_item, entity_who_picked, ...)
  modify_gold_values(entity_item, entity_who_picked)

  return _item_pickup(entity_item, entity_who_picked, ...)
end

return 0
