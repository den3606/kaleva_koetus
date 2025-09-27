local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local DurabilityCalculator = dofile_once("mods/kaleva_koetus/files/scripts/calc_wand_durability.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("A10.lua")

local WAND_DROP_SCRIPT = "mods/kaleva_koetus/files/scripts/ascensions/a10_wand_drop.lua"
local WAND_DROP_TAG = "kaleva_a10_wand_drop_attached"

local DURABILITY_VARIABLE = DurabilityCalculator.DURABILITY_VARIABLE
local DURABILITY_MAX_VARIABLE = DurabilityCalculator.DURABILITY_MAX_VARIABLE
local LAST_MANA_VARIABLE = "kaleva_a10_last_mana"
local BASE_MANA_MAX_VARIABLE = "kaleva_a10_base_mana_max"
local BASE_CHARGE_SPEED_VARIABLE = "kaleva_a10_base_charge_speed"

local DURABILITY_PER_USE = 1
local PROCESS_INTERVAL_FRAMES = 1

ascension.level = 10
ascension.name = "耐久値導入"
ascension.description = "杖に耐久値が設定される"
ascension.tag_name = AscensionTags.A10 .. "_tracked"


ascension._next_process_frame = nil

local function attach_wand_drop_handler(enemy_entity_id)
  if EntityHasTag(enemy_entity_id, WAND_DROP_TAG) then
    return
  end

  local component_id = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_death = WAND_DROP_SCRIPT,
    remove_after_executed = true,
    execute_every_n_frame = -1,
  })

  if component_id then
    EntityAddTag(enemy_entity_id, WAND_DROP_TAG)
  end
end

local function ensure_internal_float(entity_id, name, value)
  if GetInternalVariableValue(entity_id, name, "value_float") ~= nil then
    return
  end
  AddNewInternalVariable(entity_id, name, "value_float", value)
end

local function ensure_variables(wand_entity_id, ability_component)
  local max_durability = GetInternalVariableValue(wand_entity_id, DURABILITY_MAX_VARIABLE, "value_float")
  local durability = GetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float")
  if max_durability and durability then
    max_durability = math.floor(max_durability)
    SetInternalVariableValue(wand_entity_id, DURABILITY_MAX_VARIABLE, "value_float", max_durability)
    return max_durability
  end

  DurabilityCalculator.assign(wand_entity_id, ability_component)

  max_durability = GetInternalVariableValue(wand_entity_id, DURABILITY_MAX_VARIABLE, "value_float")
  durability = GetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float") or max_durability

  if max_durability then
    max_durability = math.floor(max_durability)
    SetInternalVariableValue(wand_entity_id, DURABILITY_MAX_VARIABLE, "value_float", max_durability)
  else
    max_durability = 120
    ensure_internal_float(wand_entity_id, DURABILITY_MAX_VARIABLE, max_durability)
  end

  if durability then
    durability = math.floor(durability)
    SetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float", durability)
  else
    ensure_internal_float(wand_entity_id, DURABILITY_VARIABLE, max_durability)
    durability = max_durability
  end

  local mana_max = ComponentGetValue2(ability_component, "mana_max") or 0
  local mana = ComponentGetValue2(ability_component, "mana") or mana_max
  local mana_charge_speed = ComponentGetValue2(ability_component, "mana_charge_speed") or 0

  ensure_internal_float(wand_entity_id, LAST_MANA_VARIABLE, mana)
  ensure_internal_float(wand_entity_id, BASE_MANA_MAX_VARIABLE, mana_max)
  ensure_internal_float(wand_entity_id, BASE_CHARGE_SPEED_VARIABLE, mana_charge_speed)

  EntityAddTag(wand_entity_id, ascension.tag_name)

  return max_durability
end

local function update_wand_stats(wand_entity_id, ability_component, durability, durability_max)
  if durability < 0 then
    durability = 0
  end
  local ratio = 0
  if durability_max > 0 then
    ratio = math.max(0.0, math.min(1.0, durability / durability_max))
  end

  local base_mana_max = GetInternalVariableValue(wand_entity_id, BASE_MANA_MAX_VARIABLE, "value_float") or 0
  local base_charge_speed = GetInternalVariableValue(wand_entity_id, BASE_CHARGE_SPEED_VARIABLE, "value_float") or 0

  local new_mana_max = base_mana_max * ratio
  ComponentSetValue2(ability_component, "mana_max", new_mana_max)

  local current_mana = ComponentGetValue2(ability_component, "mana") or 0
  if current_mana > new_mana_max then
    ComponentSetValue2(ability_component, "mana", new_mana_max)
    current_mana = new_mana_max
  end

  ComponentSetValue2(ability_component, "mana_charge_speed", base_charge_speed * ratio)

  return ratio, current_mana
end

local function deteriorate_wand(wand_entity_id)
  local ability_component = EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
  if not ability_component then
    return
  end

  local durability_max = ensure_variables(wand_entity_id, ability_component)
  durability_max = math.floor(durability_max or 0)
  if durability_max <= 0 then
    return
  end

  local durability_value = GetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float")
  local durability = math.floor(durability_value or durability_max)
  if durability > durability_max then
    durability = durability_max
  elseif durability < 0 then
    durability = 0
  end
  SetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float", durability)

  local last_mana = GetInternalVariableValue(wand_entity_id, LAST_MANA_VARIABLE, "value_float")
  local current_mana = ComponentGetValue2(ability_component, "mana") or 0
  if not last_mana then
    last_mana = current_mana
  end

  local mana_diff = last_mana - current_mana
  local uses = 0
  if mana_diff > 0.01 then
    uses = 1
  end
  if uses > 0 then
    durability = durability - (uses * DURABILITY_PER_USE)
    if durability < 0 then
      durability = 0
    end
    SetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float", durability)
  end

  local ratio
  ratio, current_mana = update_wand_stats(wand_entity_id, ability_component, durability, durability_max)

  SetInternalVariableValue(wand_entity_id, LAST_MANA_VARIABLE, "value_float", current_mana)

  if ratio <= 0 then
    EntityKill(wand_entity_id)
    GamePrint("Your wand crumbled to dust...")
  end
end

local function process_wands()
  local wand_ids = EntityGetWithTag("wand")
  if not wand_ids then
    return
  end

  for _, wand_id in ipairs(wand_ids) do
    deteriorate_wand(wand_id)
  end
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity = tonumber(payload[1])
  if not enemy_entity then
    return
  end

  if EntityHasTag(enemy_entity, WAND_DROP_TAG) then
    return
  end

  local damage_model = EntityGetFirstComponent(enemy_entity, "DamageModelComponent")
  if not damage_model then
    return
  end

  attach_wand_drop_handler(enemy_entity)
end

function ascension:on_activate()
  log:info("Wand durability enabled")
  self._next_process_frame = GameGetFrameNum()
end

function ascension:on_update()
  local current_frame = GameGetFrameNum()
  if self._next_process_frame and current_frame < self._next_process_frame then
    return
  end

  process_wands()
  self._next_process_frame = current_frame + PROCESS_INTERVAL_FRAMES
end

return ascension
