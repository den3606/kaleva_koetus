local reduce_potion = dofile_once("mods/kaleva_koetus/files/scripts/items/reduce_potion_capacity.lua")

local MATERIAL_SCALE = 0.5

-- selene: allow(unused_variable)
function item_pickup(entity_item, _entity_pickupper, _item_name)
  if entity_item == 0 or EntityGetIsAlive(entity_item) == false then
    return
  end

  reduce_potion(entity_item, MATERIAL_SCALE)
end
