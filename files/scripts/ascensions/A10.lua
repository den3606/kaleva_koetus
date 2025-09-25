local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/variable_storage.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A10")

local DURABILITY_VARIABLE = "kaleva_a10_durability"
local DURABILITY_MAX_VARIABLE = "kaleva_a10_durability_max"
local LAST_MANA_VARIABLE = "kaleva_a10_last_mana"
local BASE_MANA_MAX_VARIABLE = "kaleva_a10_base_mana_max"
local BASE_CHARGE_SPEED_VARIABLE = "kaleva_a10_base_charge_speed"

local DURABILITY_PER_MANA = 0.5
local PROCESS_INTERVAL_FRAMES = 10

ascension.level = 10
ascension.name = "耐久値導入"
ascension.description = "杖に耐久値が設定される"
ascension.tag_name = AscensionTags.A10 .. "_tracked"

ascension._next_process_frame = nil

local function ensure_variables(wand_entity_id, ability_component)
  local durability = GetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float")
  if durability then
    return durability
  end

  local mana_max = ComponentGetValue2(ability_component, "mana_max") or 0
  local mana_charge_speed = ComponentGetValue2(ability_component, "mana_charge_speed") or 0
  local max_durability = math.max(50.0, mana_max * 2.5)

  AddNewInternalVariable(wand_entity_id, DURABILITY_MAX_VARIABLE, "value_float", max_durability)
  AddNewInternalVariable(wand_entity_id, DURABILITY_VARIABLE, "value_float", max_durability)
  AddNewInternalVariable(wand_entity_id, LAST_MANA_VARIABLE, "value_float", ComponentGetValue2(ability_component, "mana") or mana_max)
  AddNewInternalVariable(wand_entity_id, BASE_MANA_MAX_VARIABLE, "value_float", mana_max)
  AddNewInternalVariable(wand_entity_id, BASE_CHARGE_SPEED_VARIABLE, "value_float", mana_charge_speed)

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
  local durability = GetInternalVariableValue(wand_entity_id, DURABILITY_VARIABLE, "value_float") or durability_max
  local last_mana = GetInternalVariableValue(wand_entity_id, LAST_MANA_VARIABLE, "value_float")

  local current_mana = ComponentGetValue2(ability_component, "mana") or 0
  if not last_mana then
    last_mana = current_mana
  end

  local mana_diff = last_mana - current_mana
  if mana_diff > 0 then
    durability = durability - (mana_diff * DURABILITY_PER_MANA)
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
