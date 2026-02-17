local entity_id = GetUpdatedEntityID()

local old_damage

local projectile_component_id = EntityGetFirstComponent(entity_id, "ProjectileComponent")
if projectile_component_id ~= nil then
  old_damage = ComponentGetValue2(projectile_component_id, "damage")
end

local _ = dofile("data/scripts/projectiles/food_clock.lua")

if old_damage == nil then
  return
end

projectile_component_id = EntityGetFirstComponent(entity_id, "ProjectileComponent")
if projectile_component_id == nil then
  return
end

local damage = ComponentGetValue2(projectile_component_id, "damage")
damage = old_damage + (damage - old_damage) * 0.1
ComponentSetValue2(projectile_component_id, "damage", damage)
