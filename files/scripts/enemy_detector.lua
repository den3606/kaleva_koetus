local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local EnemyDetector = {}

-- Private boss activation check functions
local function is_active_boss_centipede(entity_id)
  -- Kolmi - check if it has the active tag
  return EntityHasTag(entity_id, "boss_centipede_active")
end

local function is_active_boss_limbs(entity_id)
  -- Kolmi's limbs - check if fully spawned
  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  return damage_model ~= nil
end

local function is_active_boss_dragon(entity_id)
  -- Dragon - usually spawned directly, so always active
  return true
end

local function is_active_boss_robot(entity_id)
  -- Robot boss - check if fully initialized
  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  return damage_model ~= nil
end

local function is_active_boss_alchemist(entity_id)
  -- Alchemist - usually spawned directly
  return true
end

local function is_active_boss_ghost(entity_id)
  -- Ghost boss - check if fully materialized
  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  return damage_model ~= nil
end

local function is_active_boss_wizard(entity_id)
  -- Wizard boss - check if fully spawned
  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  return damage_model ~= nil
end

local function is_active(entity_id)
  -- Check if this enemy is a boss and apply boss-specific activation check
  -- Boss configuration with activation check functions
  local boss_configs = {
    { tag = "boss_centipede", is_active = is_active_boss_centipede },
    { tag = "boss_limbs", is_active = is_active_boss_limbs },
    { tag = "boss_dragon", is_active = is_active_boss_dragon },
    { tag = "boss_robot", is_active = is_active_boss_robot },
    { tag = "boss_alchemist", is_active = is_active_boss_alchemist },
    { tag = "boss_ghost", is_active = is_active_boss_ghost },
    { tag = "boss_wizard", is_active = is_active_boss_wizard },
  }

  -- Check each boss type
  for _, config in ipairs(boss_configs) do
    if EntityHasTag(entity_id, config.tag) then
      -- Found a boss, use its specific activation check
      local is_ready = config.is_active(entity_id)
      if is_ready then
        print("[EnemyDetector] Boss ready for processing: " .. config.tag)
      end
      return is_ready
    end
  end

  -- Not a boss, always active
  return true
end

-- Initialize enemy detector
function EnemyDetector:init()
  print("[EnemyDetector] Initialized (stateless mode)")
end

-- Get all unprocessed enemies (enemies without ascension tags)
function EnemyDetector:get_unprocessed_enemies()
  local all_enemies = EntityGetWithTag("enemy")
  local unprocessed_enemies = {}

  for _, entity_id in ipairs(all_enemies) do
    -- Check if enemy has already been detected by EnemyDetector
    local already_detected = EntityHasTag(entity_id, "kaleva_enemy_detected")

    if not already_detected then
      local x, y = EntityGetTransform(entity_id)
      if is_active(entity_id) then
        -- Mark as detected to prevent duplicate events
        EntityAddTag(entity_id, "kaleva_enemy_detected")

        table.insert(unprocessed_enemies, {
          id = entity_id,
          x = x,
          y = y,
        })
      end
    end
  end

  return unprocessed_enemies
end

return EnemyDetector
