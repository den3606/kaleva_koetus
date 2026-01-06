local reduce_potion = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a7_reduce_potion_capacity.lua")

-- selene: allow(unused_variable)
function item_pickup(entity_item, entity_pickupper, item_name)
  if entity_item == 0 or EntityGetIsAlive(entity_item) == false then
    return
  end

  reduce_potion(entity_item)
end
