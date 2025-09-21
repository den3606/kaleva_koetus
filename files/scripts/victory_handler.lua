-- Victory Handler for Kaleva Koetus
-- Detects game completion and unlocks next ascension level

local VictoryHandler = {}

-- Check if the final boss (Kolmisilmä) has been defeated
function VictoryHandler:check_boss_defeated()
  -- Check for the boss entity
  local boss_entities = EntityGetWithTag("boss_centipede") or {}
  if #boss_entities == 0 then
    -- Also check for the altar boss
    boss_entities = EntityGetWithTag("boss_wizard") or {}
  end

  -- If boss entities exist, check if they're dead
  for _, entity_id in ipairs(boss_entities) do
    local damage_comp = EntityGetFirstComponent(entity_id, "DamageModelComponent")
    if damage_comp then
      local hp = ComponentGetValue2(damage_comp, "hp")
      if hp <= 0 then
        return true
      end
    end
  end

  return false
end

-- Check if player has reached the "Work" (completion portal)
function VictoryHandler:check_work_entered()
  -- Check for the work portal entity interaction
  local portal_entities = EntityGetWithTag("ending_happiness") or {}
  if #portal_entities > 0 then
    local player = EntityGetWithTag("player_unit")[1]
    if player then
      local px, py = EntityGetTransform(player)
      for _, portal in ipairs(portal_entities) do
        local portal_x, portal_y = EntityGetTransform(portal)
        local distance = math.sqrt((px - portal_x)^2 + (py - portal_y)^2)
        if distance < 20 then -- Within interaction distance
          return true
        end
      end
    end
  end

  return false
end

-- Check for standard victory conditions
function VictoryHandler:check_victory()
  -- Check multiple victory conditions
  if self:check_boss_defeated() then
    return true
  end

  if self:check_work_entered() then
    return true
  end

  -- Check for the sampo/completion flag
  if GlobalsGetValue("ENDING_HAPPINESS_COMPLETE", "0") == "1" then
    return true
  end

  -- Check for other completion indicators (can be extended as needed)
  -- Note: Removed invalid GAME_EFFECT check that was causing enum errors

  return false
end

-- Handle victory
function VictoryHandler:on_victory()
  -- Make sure we only process victory once per run
  if GlobalsGetValue("kaleva_koetus_victory_processed", "0") == "1" then
    return
  end

  GlobalsSetValue("kaleva_koetus_victory_processed", "1")

  -- Call the ascension manager's victory handler
  local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
  AscensionManager:on_victory()

  -- Display victory message with ascension info
  local info = AscensionManager:get_ascension_info()
  if info.current > 0 then
    GamePrint("Victory on Ascension " .. info.current .. "!")
    if info.current < 20 and info.current == info.highest_unlocked then
      GamePrint("Ascension " .. (info.current + 1) .. " unlocked!")
    end
  end
end

return VictoryHandler