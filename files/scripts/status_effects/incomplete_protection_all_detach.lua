local entity_id = GetUpdatedEntityID()

local effect_entities = EntityGetAllChildren(entity_id, "effect_protection")
if effect_entities ~= nil then
  for _, effect_entity_id in ipairs(effect_entities) do
    local effect_components = EntityGetComponent(effect_entity_id, "GameEffectComponent", "effect_protection_all")
    if effect_components ~= nil then
      for _, effect_component_id in ipairs(effect_components) do
        local custom_effect_id = ComponentGetValue2(effect_component_id, "custom_effect_id")
        if custom_effect_id == "INCOMPLETE_PROTECTION_ALL" then
          return
        end
      end
    end
  end
end

local component_id = GetUpdatedComponentID()
EntityRemoveComponent(entity_id, component_id)
