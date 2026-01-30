local generate_item_with_price = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b2_generate_shop_item.lua")

-- selene: allow(unused_variable)
function spawn_hp(x, y)
  generate_item_with_price("data/entities/items/pickup/heart_fullhp_temple.xml", x - 16, y, 1000)
  local _ = EntityLoad("data/entities/buildings/music_trigger_temple.xml", x - 16, y)
  generate_item_with_price("data/entities/items/pickup/spell_refresh.xml", x + 16, y, 800)
  _ = EntityLoad("data/entities/buildings/coop_respawn.xml", x, y)
end
