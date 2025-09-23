local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 2
ascension.name = "Ascension 2"
ascension.description = "ショップの品揃えが減少する (杖-1 / スペル-2)"

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

function ascension:on_activate()
  print("[Kaleva Koetus A2] Decrease card/wand - Active")
end

function ascension:on_shop_card_spawn(payload)
  print("[Kaleva Koetus A2] Delete 2 shop cards")

  local entity_ids = payload[1]
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])

  local first_id, second_id = pick_random_two(entity_ids, x, y)
  if first_id then
    EntityKill(first_id)
  end
  if second_id then
    EntityKill(second_id)
  end
end

function ascension:on_shop_wand_spawn(payload)
  print("[Kaleva Koetus A2] Delete 1 shop wand")

  local entity_ids = payload[1]
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])

  SetRandomSeed(x, y)
  local rand = Random(1, #entity_ids)
  EntityKill(entity_ids[rand])
end

return ascension
