local function on_open(entity_item)
  local x, y = EntityGetTransform(entity_item)
  local rand_x = x
  local rand_y = y

  local position_comp = EntityGetFirstComponent(entity_item, "PositionSeedComponent")
  if position_comp then
    rand_x = ComponentGetValue2(position_comp, "pos_x")
    rand_y = ComponentGetValue2(position_comp, "pos_y")
  end

  rand_x = rand_x + 509.7
  rand_y = rand_y + 683.1

  SetRandomSeed(rand_x, rand_y)

  local entity_id = EntityLoad("data/entities/projectiles/bomb_small.xml", rand_x, rand_y)
  EntityApplyTransform(entity_id, x + Random(-10, 10), y - 4 + Random(-5, 5))

  local _ = EntityLoad("data/entities/particles/image_emitters/chest_effect_bad.xml", x, y)
end

-- selene: allow(unused_variable)
function item_pickup(entity_item, _entity_who_picked, _name)
  GamePrintImportant("$log_chest", "")
  on_open(entity_item)
  EntityKill(entity_item)
end

-- selene: allow(unused_variable)
function physics_body_modified(_is_destroyed)
  local entity_item = GetUpdatedEntityID()
  on_open(entity_item)

  local item_component_id = EntityGetFirstComponent(entity_item, "ItemComponent")
  if item_component_id ~= nil then
    EntitySetComponentIsEnabled(entity_item, item_component_id, false)
  end

  EntityKill(entity_item)
end
