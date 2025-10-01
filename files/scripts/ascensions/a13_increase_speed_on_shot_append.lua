local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("a13_increase_speed_on_shot_append.lua")

local ELITE_PROJECTILE_SPEED = 1.5

-- selene: allow(unused_variable)
function shot(projectile_entity_id)
  log:debug("elite enemy shot")
  local projectile_component_id = EntityGetComponent(projectile_entity_id, "ProjectileComponent")
  local speed_min = ComponentGetValue2(projectile_component_id, "speed_min")
  local speed_max = ComponentGetValue2(projectile_component_id, "speed_max")

  ComponentSetValue2(projectile_component_id, "speed_min", speed_min * ELITE_PROJECTILE_SPEED)
  ComponentSetValue2(projectile_component_id, "speed_max", speed_max * ELITE_PROJECTILE_SPEED)
end
