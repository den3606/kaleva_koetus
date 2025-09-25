local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A1")

ascension.level = 1
ascension.name = "敵HP上昇"
ascension.description = "敵のHPが2倍に増加"
ascension.hp_multiplier = 2

function ascension:on_activate()
  log:info("Enemy HP increase active (x%d)", self.hp_multiplier)
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity = tonumber(payload[1])
  if not enemy_entity then
    return
  end

  local tag_name = AscensionTags.A1 .. EventTypes.ENEMY_SPAWN
  if EntityHasTag(enemy_entity, tag_name) then
    log:debug("Entity %d already processed, skipping", enemy_entity)
    return
  end

  local damage_model = EntityGetFirstComponent(enemy_entity, "DamageModelComponent")
  if damage_model then
    local current_hp = ComponentGetValue2(damage_model, "hp")
    local max_hp = ComponentGetValue2(damage_model, "max_hp")

    local new_hp = current_hp * self.hp_multiplier
    local new_max_hp = max_hp * self.hp_multiplier

    ComponentSetValue2(damage_model, "hp", new_hp)
    ComponentSetValue2(damage_model, "max_hp", new_max_hp)

    EntityAddTag(enemy_entity, tag_name)

    log:debug("Entity %d HP %.1f -> %.1f, MaxHP %.1f -> %.1f", enemy_entity, current_hp, new_hp, max_hp, new_max_hp)
  else
    log:warn("No DamageModelComponent found for entity %d", enemy_entity)
  end
end

return ascension
