-- Ascension 1: 敵HP上昇
-- 敵のHPが1.1倍に増加

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = {}

-- Metadata
ascension.level = 1
ascension.name = "敵HP上昇"
ascension.description = "敵のHPが1.5倍に増加"
ascension.hp_multiplier = 1.5

-- Called when this ascension level is activated
function ascension:on_activate()
  print("[Kaleva Koetus A1] Enemy HP increase - Active (x" .. self.hp_multiplier .. ")")
end

-- Called every frame while this ascension is active (optional)
function ascension:on_update()
  -- Implement per-frame updates if needed
end

-- Called when player spawns with this ascension active
function ascension:on_player_spawn()
  -- Implement player-specific modifications
  -- Examples:
  -- - Modify starting HP
  -- - Change starting perks
  -- - Adjust player stats
end

-- Called when an enemy spawns (event handler)
function ascension:on_enemy_spawn(event_args)
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

-- Called to check if the next ascension level should be unlocked
function ascension:should_unlock_next()
  -- Return true if player has met conditions to unlock next level
  return true -- Victory with A1 unlocks A2
end

return ascension
