-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("a13_increase_speed_on_shot_append.lua")

local ELITE_PROJECTILE_SPEED = 1.5

-- selene: allow(unused_variable)
function shot(projectile_entity_id)
  -- log:debug("elite enemy shot")
  local velocity_component_id = EntityGetFirstComponent(projectile_entity_id, "VelocityComponent")
  if velocity_component_id ~= nil then
    return
  end

  local velocity_x, velocity_y = ComponentGetValue2(velocity_component_id, "mVelocity")
  ComponentSetValue2(velocity_component_id, "mVelocity", velocity_x * ELITE_PROJECTILE_SPEED, velocity_y * ELITE_PROJECTILE_SPEED)
end
