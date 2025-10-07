-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("a13_increase_damage_on_shot_append.lua")
local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/variable_storage.lua")

local DAMAGE_PROJECTILE_MULTIPLIER = 2

-- selene: allow(unused_variable)
function shot(projectile_entity_id)
  -- log:debug("elite enemy shot")
  local projectile_component_id = EntityGetFirstComponent(projectile_entity_id, "ProjectileComponent")
  local damage = ComponentGetValue2(projectile_component_id, "damage")
  ComponentSetValue2(projectile_component_id, "damage", damage * DAMAGE_PROJECTILE_MULTIPLIER)

  local explosion_damage = ComponentObjectGetValue2(projectile_component_id, "config_explosion", "damage")
  ComponentObjectSetValue2(projectile_component_id, "config_explosion", "damage", explosion_damage * DAMAGE_PROJECTILE_MULTIPLIER)
end
