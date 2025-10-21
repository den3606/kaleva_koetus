local entity_id = GetUpdatedEntityID()

local parent_entity_id = EntityGetParent(entity_id)
if parent_entity_id == 0 then
  EntityKill(entity_id)
end
