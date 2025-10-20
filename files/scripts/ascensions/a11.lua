-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a11.lua")

local SPAWN_CHANCE_1 = 0.25
local SPAWN_CHANCE_2 = 0.10
local SPAWN_CHANCE_3 = 0.05

ascension.level = 11
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A11 .. EventTypes.ENEMY_SPAWN

local function is_boss_entity(entity_id)
  if not entity_id or entity_id == 0 then
    return false
  end

  local tags = EntityGetTags(entity_id)
  if not tags then
    return false
  end

  for tag in string.gmatch(tags, "[^,]+") do
    if tag == "boss" or string.find(tag, "boss_", 1, true) then
      return true
    end
  end

  return false
end

local function duplicate_enemy(enemy_entity_id, x, y, how_many)
  local entity_filename = EntityGetFilename(enemy_entity_id)
  if not entity_filename or entity_filename == "" then
    return
  end

  SetRandomSeed(x, y)
  for _ = 1, how_many, 1 do
    local offset_x = Random(-16, 16)
    local offset_y = Random(-16, 0)
    local duplicate_id = EntityLoad(entity_filename, x + offset_x, y + offset_y)
    if duplicate_id then
      EntityAddTag(duplicate_id, ascension.tag_name)
      -- log:verbose("Spawned extra enemy %d from %d", duplicate_id, enemy_entity_id)
    end
  end
end

function ascension:on_activate()
  -- log:info("Increasing enemy spawns")
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity_id = tonumber(payload[1])
  local x = tonumber(payload[2]) or 0
  local y = tonumber(payload[3]) or 0

  if not enemy_entity_id or enemy_entity_id == 0 then
    return
  end

  if EntityHasTag(enemy_entity_id, ascension.tag_name) then
    return
  end

  if is_boss_entity(enemy_entity_id) then
    -- log:debug("Skipping boss entity %d for duplication", enemy_entity_id)
    return
  end

  local seed_x = math.floor(x)
  local seed_y = math.floor(y + GameGetFrameNum())
  SetRandomSeed(seed_x, seed_y)
  local randf = Randomf()
  if randf <= SPAWN_CHANCE_3 then
    -- log:verbose("4 enemy")
    duplicate_enemy(enemy_entity_id, x, y, 3)
  elseif randf <= SPAWN_CHANCE_2 then
    -- log:verbose("3 enemy")
    duplicate_enemy(enemy_entity_id, x, y, 2)
  elseif randf <= SPAWN_CHANCE_1 then
    -- log:verbose("2 enemy")
    duplicate_enemy(enemy_entity_id, x, y, 1)
  end
end

return ascension
