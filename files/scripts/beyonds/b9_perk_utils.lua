---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_get_variable_storage = VariableUtils.entity_get_variable_storage
local entity_add_variable_storage = VariableUtils.entity_add_variable_storage

---@class PerkData
---
---@field id string
---@field ui_name string
---@field ui_description string
---@field ui_icon string
---
---@field perk_icon string? "data/items_gfx/perk.xml"
---@field particle_effect string?
---
---@field game_effect string?
---@field game_effect2 string?
---@field one_off_effect boolean? false
---@field do_not_remove boolean? false
---@field remove_other_perks string[]?
---
---@field func (fun(entity_item:number, entity_who_picked:number, item_name:string, pickup_count:number, ...):...)?
---@field func_remove (fun(entity_who_picked:number, ...):...)?
---
---@field usable_by_enemies boolean? false
---@field func_enemy (fun(entity_item:number, entity_who_picked:number, ...):...)?
---
---@field not_in_default_perk_pool boolean? false
---@field stackable boolean? false
---@field max_in_perk_pool number? 2
---@field stackable_is_rare boolean? false
---@field stackable_how_often_reappears number? `PerkUtils.MIN_DISTANCE_BETWEEN_DUPLICATE_PERKS`
---@field stackable_maximum number? `PerkUtils.DEFAULT_MAX_STACKABLE_PERK_COUNT`
---
---@field private __isPerkData true

---@class PerkUtils
local PerkUtils = {}

PerkUtils.MIN_DISTANCE_BETWEEN_DUPLICATE_PERKS = 4
PerkUtils.DEFAULT_MAX_STACKABLE_PERK_COUNT = 128

---@param entity_id number
---@param game_effect_name string
---@return number[]
local function get_game_effect_components(entity_id, game_effect_name)
  local game_effect_components = {}
  for i = 1, GameGetGameEffectCount(entity_id, game_effect_name) do
    local game_effect_component_id = GameGetGameEffect(entity_id, game_effect_name)
    if game_effect_component_id ~= 0 then
      game_effect_components[i] = game_effect_component_id
      EntitySetComponentIsEnabled(entity_id, game_effect_component_id, false)
    end
  end
  for _, game_effect_component_id in ipairs(game_effect_components) do
    EntitySetComponentIsEnabled(entity_id, game_effect_component_id, true)
  end
  return game_effect_components
end

PerkUtils.get_game_effect_components = get_game_effect_components

---@param entity_id number
---@param game_effect_name string
---@param tag string
---@return number
function PerkUtils.get_tagged_game_effect_count(entity_id, game_effect_name, tag)
  local tagged_game_effect_count = 0
  local effect_entity_has_tag = {}
  local effect_components = get_game_effect_components(entity_id, game_effect_name)
  for _, effect_component_id in ipairs(effect_components) do
    local effect_entity_id = ComponentGetEntity(effect_component_id)
    local has_variable_tag = effect_entity_has_tag[effect_entity_id]
    if has_variable_tag == nil then
      has_variable_tag = entity_has_variable_tag(effect_entity_id, tag)
      effect_entity_has_tag[effect_entity_id] = has_variable_tag
    end
    if has_variable_tag == true then
      tagged_game_effect_count = tagged_game_effect_count + 1
    end
  end
  return tagged_game_effect_count
end

---@param entity_who_picked number
---@param perk_id string
---@return number
function PerkUtils.get_perk_pickup_count(entity_who_picked, perk_id)
  local variable_storage_component_id = entity_get_variable_storage(entity_who_picked, "kaleva_koetus_" .. perk_id .. "_count")

  if variable_storage_component_id == nil then
    return 0
  end

  return ComponentGetValue2(variable_storage_component_id, "value_int")
end

---@param entity_who_picked number
---@param perk_id string
---@param amount number?
---@return number
function PerkUtils.add_perk_pickup_count(entity_who_picked, perk_id, amount)
  amount = amount or 1

  local variable_storage_component_id = entity_add_variable_storage(entity_who_picked, "kaleva_koetus_" .. perk_id .. "_count")
  local pickup_count = ComponentGetValue2(variable_storage_component_id, "value_int")
  pickup_count = pickup_count + amount
  ComponentSetValue2(variable_storage_component_id, "value_int", pickup_count)

  return pickup_count
end

---@param entity_who_picked number
---@param perk_id string
function PerkUtils.reset_perk_pickup_count(entity_who_picked, perk_id)
  local variable_storage_component_id = entity_get_variable_storage(entity_who_picked, "kaleva_koetus_" .. perk_id .. "_count")

  if variable_storage_component_id == nil then
    return
  end

  EntityRemoveComponent(entity_who_picked, variable_storage_component_id)
end

return PerkUtils
