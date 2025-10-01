local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("a13_increase_explosion_on_shot_append.lua")

local ELITE_EXPLOSION_RADIUS_MULTIPLIER = 2
local ELITE_EXPLOSION_STAINS_RADIUS = 1.5

-- selene: allow(unused_variable)
function shot(projectile_entity_id)
  log:debug("elite enemy shot")
  local projectile_component_id = EntityGetFirstComponent(projectile_entity_id, "ProjectileComponent")
  local explosion_radius = ComponentObjectGetValue2(projectile_component_id, "config_explosion", "explosion_radius")
  local stains_radius = ComponentObjectGetValue2(projectile_component_id, "config_explosion", "stains_radius")
  ComponentObjectSetValue2(
    projectile_component_id,
    "config_explosion",
    "explosion_radius",
    explosion_radius * ELITE_EXPLOSION_RADIUS_MULTIPLIER
  )
  ComponentObjectSetValue2(projectile_component_id, "config_explosion", "stains_radius", stains_radius * ELITE_EXPLOSION_STAINS_RADIUS)
end
