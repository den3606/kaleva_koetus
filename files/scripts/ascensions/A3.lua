local Logger = KalevaLogger or dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A3")

ascension.level = 3
ascension.name = "Ascension 3"
ascension.description = "開始HPが70"
ascension.tag_name = AscensionTags.A3 .. EventTypes.ENEMY_SPAWN

local TARGET_HP = 70
local HP_TO_ENTITY_UNITS = 0.04

local function to_entity_health(hit_points)
  return hit_points * HP_TO_ENTITY_UNITS
end

function ascension:on_activate()
  log:info("Reduced starting HP active (set to %d)", TARGET_HP)
end

function ascension:on_player_spawn(player_entity_id)
  if EntityHasTag(player_entity_id, ascension.tag_name) then
    return
  end

  local damage_model = EntityGetFirstComponent(player_entity_id, "DamageModelComponent")
  if not damage_model then
    error("[Kaleva Koetus A3] Player DamageModelComponent not found")
  end

  local current_hp = ComponentGetValue2(damage_model, "hp")
  local current_max_hp = ComponentGetValue2(damage_model, "max_hp")
  local target_health = to_entity_health(TARGET_HP)

  ComponentSetValue2(damage_model, "max_hp", target_health)
  ComponentSetValue2(damage_model, "hp", target_health)

  EntityAddTag(player_entity_id, ascension.tag_name)

  log:debug(
    "Player HP adjusted %.2f -> %.2f, MaxHP %.2f -> %.2f",
    current_hp,
    target_health,
    current_max_hp,
    target_health
  )
end

return ascension
