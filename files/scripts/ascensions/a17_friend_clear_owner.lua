local entity_id = GetUpdatedEntityID()

if entity_id ~= 0 then
  local variable_storage_components = EntityGetComponent(entity_id, "VariableStorageComponent")
  if variable_storage_components ~= nil then
    for _, variable_storage_cid in ipairs(variable_storage_components) do
      if ComponentGetValue2(variable_storage_cid, "name") == "owner_id" then
        ComponentSetValue2(variable_storage_cid, "value_int", 0)
        break
      end
    end
  end
end
