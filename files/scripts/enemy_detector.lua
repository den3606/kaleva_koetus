-- Enemy Detector
-- Detects unprocessed enemies and returns them (stateless)

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local EnemyDetector = {}

-- Initialize enemy detector
function EnemyDetector:init()
  print("[EnemyDetector] Initialized (stateless mode)")
end

-- Get all unprocessed enemies (enemies without ascension tags)
function EnemyDetector:get_unprocessed_enemies()
  local all_enemies = EntityGetWithTag("enemy")
  local unprocessed_enemies = {}

  for _, entity_id in ipairs(all_enemies) do
    -- Check if enemy has already been processed by any ascension
    local already_processed = EntityHasTag(entity_id, AscensionTags.A1 .. EventTypes.ENEMY_SPAWN)

    if not already_processed then
      local x, y = EntityGetTransform(entity_id)

      table.insert(unprocessed_enemies, {
        id = entity_id,
        x = x,
        y = y
      })
    end
  end

  if #unprocessed_enemies > 0 then
    print("[EnemyDetector] Found " .. #unprocessed_enemies .. " unprocessed enemies")
  end

  return unprocessed_enemies
end

return EnemyDetector