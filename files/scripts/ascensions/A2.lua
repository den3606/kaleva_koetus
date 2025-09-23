local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 2
ascension.name = "Ascension 2"
ascension.description = "ショップの品揃えが減少する (杖-1 / スペル-2)"

function ascension:on_shop_card_spawn(payload)
  local entity_ids = tonumber(payload[1])
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])
  SetRandomSeed(x, y)

  local rand = Random(1, #entity_ids)

  EntityKill(rand)
end

function ascension:on_shop_wand_spawn(payload)
  local entity_ids = tonumber(payload[1])
  local x = tonumber(payload[2])
  local y = tonumber(payload[3])
  SetRandomSeed(x, y)

  local rand = Random(1, #entity_ids)

  EntityKill(rand)
end

return ascension
