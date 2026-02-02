local entity_id = GetUpdatedEntityID()

local root

local variable_components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
if variable_components == nil then
  return
end

for _, variable_component_id in ipairs(variable_components) do
  local name = ComponentGetValue2(variable_component_id, "name")
  if name == "player_entity_id" then
    root = ComponentGetValue2(variable_component_id, "value_int")
    break
  end
end

if root == nil then
  return
end

if root == entity_id or EntityGetIsAlive(root) == false then
  return
end

GamePickUpInventoryItem(root, entity_id, false)
