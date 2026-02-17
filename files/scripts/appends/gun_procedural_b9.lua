local NO_MORE_SHUFFLE_CHANCE = 0.5

local _GlobalsGetValue = GlobalsGetValue
function GlobalsGetValue(key, ...)
  if key == "PERK_NO_MORE_SHUFFLE_WANDS" then
    local rng

    local entity_id = GetUpdatedEntityID()
    if entity_id == -1 then
      rng = ProceduralRandomf(GameGetFrameNum() + 200, GetUpdatedEntityID() + 900)
    else
      local x, y = EntityGetTransform(entity_id)
      rng = ProceduralRandomf(x + 200, y + 900)
    end

    if rng < NO_MORE_SHUFFLE_CHANCE then
      return "0"
    end
  end

  return _GlobalsGetValue(key, ...)
end
