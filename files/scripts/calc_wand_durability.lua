local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local DepthProfile = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a10_depth_profile.lua")

local MIN_VALUE = 0.01
local MAX_RATIO = 5.0
local RANDOM_MULTIPLIER_MIN = 0.7
local RANDOM_MULTIPLIER_MAX = 1.5
local PERFORMANCE_WEIGHT = 5.0
local BASE_DURABILITY = 380.0
local LEVEL_BONUS = 120.0
local MIN_DURABILITY = 120

local STAT_CONFIG = {
  {
    object_name = "gun_config",
    property_name = "fire_rate_wait",
    direction = "lower",
    baseline = 25.0,
    weight = 0.8,
  },
  {
    object_name = "gun_config",
    property_name = "reload_time",
    direction = "lower",
    baseline = 60.0,
    weight = 1.0,
  },
  {
    property_name = "mana_max",
    direction = "higher",
    baseline = 500.0,
    weight = 0.8,
  },
  {
    property_name = "mana_charge_speed",
    direction = "higher",
    baseline = 150.0,
    weight = 1.1,
  },
  {
    object_name = "gun_config",
    property_name = "deck_capacity",
    direction = "higher",
    baseline = 8.0,
    weight = 0.7,
  },
  {
    object_name = "gun_config",
    property_name = "spread_degrees",
    direction = "lower",
    baseline = 8.0,
    weight = 0.4,
  },
}

local DurabilityCalculator = {
  DURABILITY_VARIABLE = "kaleva_a10_durability",
  DURABILITY_MAX_VARIABLE = "kaleva_a10_durability_max",
}

local function get_stat_value(ability_component, stat)
  if stat.object_name then
    return ComponentObjectGetValue2(ability_component, stat.object_name, stat.property_name) or 0
  end
  return ComponentGetValue2(ability_component, stat.property_name) or 0
end

local function compute_stat_score(value, stat)
  if stat.direction == "higher" then
    local ratio = 0
    if stat.baseline > 0 then
      ratio = value / stat.baseline
    end
    if ratio <= 1 then
      return 0
    end
    ratio = math.min(MAX_RATIO, ratio)
    return (ratio - 1) * stat.weight
  end

  local denominator = math.max(value, MIN_VALUE)
  local ratio = stat.baseline / denominator
  if ratio <= 1 then
    return 0
  end
  ratio = math.min(MAX_RATIO, ratio)
  return (ratio - 1) * stat.weight
end

local function compute_performance_score(ability_component)
  local score = 0
  for _, stat in ipairs(STAT_CONFIG) do
    local value = get_stat_value(ability_component, stat)
    score = score + compute_stat_score(value, stat)
  end
  return score
end

local function set_internal_float(entity_id, name, value)
  local existing = GetInternalVariableValue(entity_id, name, "value_float")
  if existing == nil then
    AddNewInternalVariable(entity_id, name, "value_float", value)
    return
  end
  SetInternalVariableValue(entity_id, name, "value_float", value)
end

function DurabilityCalculator.assign(wand_entity_id, ability_component)
  ability_component = ability_component or EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
  if not ability_component then
    return
  end

  local _, y = EntityGetTransform(wand_entity_id)
  local stage, depth_multiplier = DepthProfile.compute(y)
  local performance_score = compute_performance_score(ability_component)

  local base_durability = BASE_DURABILITY + (stage * LEVEL_BONUS)
  local penalty = performance_score * PERFORMANCE_WEIGHT

  local durability = base_durability - penalty
  if durability < MIN_DURABILITY then
    durability = MIN_DURABILITY
  end

  local multiplier = ProceduralRandomf(wand_entity_id, performance_score, RANDOM_MULTIPLIER_MIN, RANDOM_MULTIPLIER_MAX)
  durability = durability * multiplier
  if durability < MIN_DURABILITY then
    durability = MIN_DURABILITY
  end

  durability = durability * depth_multiplier

  durability = math.floor(durability)
  if durability < MIN_DURABILITY then
    durability = MIN_DURABILITY
  end

  set_internal_float(wand_entity_id, DurabilityCalculator.DURABILITY_MAX_VARIABLE, durability)
  set_internal_float(wand_entity_id, DurabilityCalculator.DURABILITY_VARIABLE, durability)
end

return DurabilityCalculator
