local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A17")

local RESISTANCE_FIELDS = {
  "fire_resistance",
  "explosion_resistance",
  "electricity_resistance",
  "melee_resistance",
  "drill_resistance",
  "slice_resistance",
  "projectile_resistance",
  "physics_hit_resistance",
  "radioactive_resistance",
  "poison_resistance",
  "ice_resistance",
}

local NEGATED_EFFECTS = {
  PROTECTION_FIRE = true,
  PROTECTION_ELECTRICITY = true,
  PROTECTION_EXPLOSION = true,
  PROTECTION_RADIOACTIVITY = true,
  PROTECTION_MELEE = true,
  PROTECTION_POLYMORPH = true,
  PROTECTION_FREEZE = true,
  PROTECTION_STAIN = true,
  STAINLESS_ARMOR = true,
}

ascension.level = 17
ascension.name = "耐性なし"
ascension.description = "プレイヤーの耐性がすべて剥がれる"

local function strip_resistances(player_entity_id)
  local damage_model = EntityGetFirstComponentIncludingDisabled(player_entity_id, "DamageModelComponent")
  if not damage_model then
    return
  end

  for _, field in ipairs(RESISTANCE_FIELDS) do
    pcall(ComponentSetValue2, damage_model, field, 1.0)
  end

  pcall(ComponentSetValue2, damage_model, "critical_damage_resistance", 1.0)
end

local function remove_protection_effects(player_entity_id)
  local effects = EntityGetComponentIncludingDisabled(player_entity_id, "GameEffectComponent")
  if not effects then
    return
  end

  for _, component_id in ipairs(effects) do
    local effect = ComponentGetValue2(component_id, "effect")
    if effect and NEGATED_EFFECTS[effect] then
      EntityRemoveComponent(player_entity_id, component_id)
    end
  end
end

function ascension:on_activate()
  log:info("Player resistances removed")
end

function ascension:on_player_spawn(player_entity_id)
  strip_resistances(player_entity_id)
  remove_protection_effects(player_entity_id)
end

function ascension:on_update()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  strip_resistances(player_entity_id)
  remove_protection_effects(player_entity_id)
end

return ascension
