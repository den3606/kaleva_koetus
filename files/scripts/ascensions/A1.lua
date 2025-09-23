local ascension = dofile_once("mods/kaleva_koetus/files/scripts/ascension1s/ascension1_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension1 = {}
ascension1.__index = ascension

ascension1.level = 1
ascension1.name = "敵HP上昇"
ascension1.description = "敵のHPが1.5倍に増加"
ascension1.hp_multiplier = 1.5

function ascension1:on_activate()
  print("[Kaleva Koetus A1] Enemy HP increase - Active (x" .. self.hp_multiplier .. ")")
end

-- Called when an enemy spawns (event handler)
function ascension1:on_enemy_spawn(event_args)
  -- event_args: {entity_id, x, y}
  if #event_args < 1 then
    return
  end

  local enemy_entity = tonumber(event_args[1])
  if not enemy_entity then
    return
  end

  -- Check if already processed to avoid duplicate application
  local tag_name = AscensionTags.A1 .. EventTypes.ENEMY_SPAWN
  if EntityHasTag(enemy_entity, tag_name) then
    print("[A1] Entity " .. enemy_entity .. " already processed, skipping")
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

    -- Mark as processed
    EntityAddTag(enemy_entity, tag_name)

    -- Verification log (temporary for testing)
    print(string.format("[A1] Entity %d: HP %.1f->%.1f, MaxHP %.1f->%.1f", enemy_entity, current_hp, new_hp, max_hp, new_max_hp))
  else
    print("[A1] No DamageModelComponent found for entity " .. enemy_entity)
  end
end

function ascension1:should_unlock_next()
  return true
end

return ascension1
