local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local EnemyDetector = {}

local log = Logger:new("enemy_detector.lua")

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

local function is_active_boss_dragon()
  -- Dragon - usually spawned directly, so always active
  return true
end

local function is_active_boss_robot(entity_id)
  -- Robot boss - check if fully initialized
  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  return damage_model ~= nil
end

local function is_active_boss_alchemist()
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
  local boss_configs = {
    { tag = "boss_centipede", is_active = is_active_boss_centipede },
    { tag = "boss_limbs", is_active = is_active_boss_limbs },
    { tag = "boss_dragon", is_active = is_active_boss_dragon },
    { tag = "boss_robot", is_active = is_active_boss_robot },
    { tag = "boss_alchemist", is_active = is_active_boss_alchemist },
    { tag = "boss_ghost", is_active = is_active_boss_ghost },
    { tag = "boss_wizard", is_active = is_active_boss_wizard },
  }

  for _, config in ipairs(boss_configs) do
    if EntityHasTag(entity_id, config.tag) then
      local ready = config.is_active(entity_id)
      if ready then
        log:debug("Boss ready for processing: %s", config.tag)
      end
      return ready
    end
  end

  return true
end

function EnemyDetector:init(called_from)
  self.tag_name = "kk_enemy_detected" .. "_" .. called_from
  log:debug("initialized")
end

function EnemyDetector:get_unprocessed_enemies()
  if self.latest_entity_id == EntitiesGetMaxID() then
    return {}
  end
  self.latest_entity_id = EntitiesGetMaxID()

  local all_enemies = EntityGetWithTag("enemy")
  if #all_enemies == 0 then
    return {}
  end

  local unprocessed_enemies = {}
  for _, entity_id in ipairs(all_enemies) do
    if not EntityHasTag(entity_id, self.tag_name) then
      local x, y = EntityGetTransform(entity_id)
      if is_active(entity_id) then
        EntityAddTag(entity_id, self.tag_name)

        unprocessed_enemies[#unprocessed_enemies + 1] = {
          id = entity_id,
          x = x,
          y = y,
        }
      end
    end
  end

  return unprocessed_enemies
end

return EnemyDetector
