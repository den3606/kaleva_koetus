local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("A2.lua")

ascension.level = 2
ascension.name = "Ascension 2"
ascension.description = "ショップの品揃えが減少する (杖-1 / スペル-2)"
ascension.tag_name = AscensionTags.A2 .. "_removed"

local function pick_random_two(ids, seed_a, seed_b)
  if type(ids) ~= "table" or #ids < 2 then
    return nil, nil
  end

  local copy = {}
  for i = 1, #ids do
    copy[i] = ids[i]
  end

  SetRandomSeed(seed_a, seed_b)
  for i = #copy, 2, -1 do
    local j = Random(1, i)
    copy[i], copy[j] = copy[j], copy[i]
  end

  return copy[1], copy[2]
end

local function mark_and_destroy(entity_id)
  if not entity_id then
    return
  end

  if EntityHasTag(entity_id, ascension.tag_name) then
    return
  end

  EntityAddTag(entity_id, ascension.tag_name)
  EntityKill(entity_id)
end

function ascension:on_activate()
  log:info("Shop inventory reduction active")
end

function ascension:on_shop_card_spawn(payload)
  log:debug("Removing two shop cards")

  local entity_ids = payload[1]
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])

  local first_id, second_id = pick_random_two(entity_ids, x, y)
  mark_and_destroy(first_id)
  mark_and_destroy(second_id)
end

function ascension:on_shop_wand_spawn(payload)
  log:debug("Removing one shop wand")

  local entity_ids = payload[1]
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])

  SetRandomSeed(x, y)
  local rand = Random(1, #entity_ids)
  mark_and_destroy(entity_ids[rand])
end

return ascension
