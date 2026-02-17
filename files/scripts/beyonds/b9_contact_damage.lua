local _ = dofile("data/scripts/perks/contact_damage.lua")

local entity_id = GetUpdatedEntityID()
local root_entity_id = EntityGetRootEntity(entity_id)

if entity_id ~= root_entity_id then
  local damage_model_component_id = EntityGetFirstComponent(root_entity_id, "DamageModelComponent")
  local area_damage_component_id = EntityGetFirstComponent(entity_id, "AreaDamageComponent")

  if damage_model_component_id == nil or area_damage_component_id == nil then
    return
  end

  local damage_per_frame = ComponentGetValue2(area_damage_component_id, "damage_per_frame")
  damage_per_frame = damage_per_frame * 10
  ComponentSetValue2(area_damage_component_id, "damage_per_frame", damage_per_frame)
end
