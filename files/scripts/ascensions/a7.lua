local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local reduce_potion = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a7_reduce_potion_capacity.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("a7.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 7
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

function ascension:on_mod_init()
  -- log:info("Potion volume reduced to %.0f%%", MATERIAL_SCALE * 100)
  for content in nxml.edit_file("data/entities/items/pickup/potion_aggressive.xml") do
    content:create_child("LuaComponent", {
      execute_every_n_frame = "-1",
      remove_after_executed = "1",
      script_item_picked_up = "mods/kaleva_koetus/files/scripts/appends/potion_aggressive_pick_up.lua",
    })
  end
end

function ascension:on_potion_generated(entity_id)
  if entity_id == 0 then
    return
  end

  if EntityGetIsAlive(entity_id) == false then
    return
  end

  reduce_potion(entity_id)
end

return ascension
