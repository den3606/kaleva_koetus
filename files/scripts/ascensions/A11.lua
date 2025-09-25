local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

local DUPLICATED_TAG = AscensionTags.A11 .. "duplicated"
local SPAWN_CHANCE = 0.2

ascension.level = 11
ascension.name = "モンスター増加"
ascension.description = "モンスター出現率が1.2倍"

local function duplicate_enemy(enemy_entity_id, x, y)
  local entity_filename = EntityGetFilename(enemy_entity_id)
  if not entity_filename or entity_filename == "" then
    return
  end

  local offset_x = Random(-16, 16)
  local offset_y = Random(-16, 16)
  local duplicate_id = EntityLoad(entity_filename, x + offset_x, y + offset_y)
  if duplicate_id then
    EntityAddTag(duplicate_id, DUPLICATED_TAG)
    print(string.format("[Kaleva Koetus A11] Spawned extra enemy %d from %d", duplicate_id, enemy_entity_id))
  end
end

function ascension:on_activate()
  print("[Kaleva Koetus A11] Increasing enemy spawns")
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity_id = tonumber(payload[1])
  local x = tonumber(payload[2]) or 0
  local y = tonumber(payload[3]) or 0

  if not enemy_entity_id or enemy_entity_id == 0 then
    return
  end

  if EntityHasTag(enemy_entity_id, DUPLICATED_TAG) then
    return
  end

  local seed_x = math.floor(x)
  local seed_y = math.floor(y + GameGetFrameNum())
  SetRandomSeed(seed_x, seed_y)
  if Randomf() <= SPAWN_CHANCE then
    duplicate_enemy(enemy_entity_id, x, y)
  end
end

return ascension
