local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local LevelTags = EventDefs.Tags

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 3
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

local log = Logger:new("b3.lua")

local b3_player_tag = LevelTags.B3 .. EventTypes.PLAYER_SPAWN

local HP_SCALE = 0.7
local DAMAGE_MULTIPLIER = 2

function beyond:on_mod_init()
  -- log:info("Reduced starting HP active (set to %d)", TARGET_HP)
end

function beyond:on_player_spawned(player_entity_id)
  if EntityHasTag(player_entity_id, b3_player_tag) then
    return
  end

  local damage_model = EntityGetFirstComponent(player_entity_id, "DamageModelComponent")
  if not damage_model then
    log:warn("[Kaleva Koetus B3] Player DamageModelComponent not found")
    return
  end

  local current_max_hp = ComponentGetValue2(damage_model, "max_hp")
  local target_health = current_max_hp * HP_SCALE

  ComponentSetValue2(damage_model, "max_hp", target_health)
  ComponentSetValue2(damage_model, "hp", target_health)

  local damage_types = {
    "projectile",
    "electricity",
    "explosion",
    "fire",
    "melee",
    "drill",
    "slice",
    "ice",
    -- "healing",
    "physics_hit",
    "radioactive",
    "poison",
    -- "overeating",
    "curse",
    "holy",
  }
  for _, damage_type in ipairs(damage_types) do
    local value = ComponentObjectGetValue2(damage_model, "damage_multipliers", damage_type)
    value = value * DAMAGE_MULTIPLIER
    ComponentObjectSetValue2(damage_model, "damage_multipliers", damage_type, value)
  end

  EntityAddTag(player_entity_id, b3_player_tag)
end

return beyond
