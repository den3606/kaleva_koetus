-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 3
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a3.lua")

local a3_player_tag = AscensionTags.A3 .. EventTypes.PLAYER_SPAWN

local HP_SCALE = 0.7

function ascension:on_mod_init()
  -- log:info("Reduced starting HP active (set to %d)", TARGET_HP)
end

function ascension:on_player_spawned(player_entity_id)
  if EntityHasTag(player_entity_id, a3_player_tag) then
    return
  end

  local damage_model = EntityGetFirstComponent(player_entity_id, "DamageModelComponent")
  if not damage_model then
    error("[Kaleva Koetus A3] Player DamageModelComponent not found")
  end

  local current_max_hp = ComponentGetValue2(damage_model, "max_hp")
  local target_health = current_max_hp * HP_SCALE

  ComponentSetValue2(damage_model, "max_hp", target_health)
  ComponentSetValue2(damage_model, "hp", target_health)

  EntityAddTag(player_entity_id, a3_player_tag)

  -- log:debug("Player HP adjusted %.2f -> %.2f, MaxHP %.2f -> %.2f", current_hp, target_health, current_max_hp, target_health)
end

return ascension
