local MATERIAL_SCALE = 0.5

local function reduce_potion(potion_entity_id)
  local component_id = EntityGetFirstComponentIncludingDisabled(potion_entity_id, "MaterialSuckerComponent")
  if component_id == nil then
    return
  end

  local original_barrel_size = ComponentGetValue2(component_id, "barrel_size")
  local resized_barrel_size = math.floor(original_barrel_size * MATERIAL_SCALE)
  ComponentSetValue2(component_id, "barrel_size", resized_barrel_size)

  component_id = EntityGetFirstComponentIncludingDisabled(potion_entity_id, "MaterialInventoryComponent")
  if component_id == nil then
    return
  end

  local count_per_material_type = ComponentGetValue2(component_id, "count_per_material_type")
  RemoveMaterialInventoryMaterial(potion_entity_id)

  local sum_original = 0
  local sum_now = 0
  for index, count in ipairs(count_per_material_type) do
    if count > 0 then
      sum_original = sum_original + count
      local sum_scaled = math.floor(sum_original * MATERIAL_SCALE)
      if sum_scaled > sum_now then
        AddMaterialInventoryMaterial(potion_entity_id, CellFactory_GetName(index - 1), sum_scaled - sum_now)
        sum_now = sum_scaled
      end
    end
  end
end

return reduce_potion
