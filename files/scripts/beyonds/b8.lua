-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 8
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

-- local log = Logger:new("b8.lua")

function beyond:on_mod_init()
  -- log:info("Preventing tablet spawns")
  ModLuaFileAppend("data/scripts/biome_scripts.lua", "mods/kaleva_koetus/files/scripts/appends/biome_scripts_b8.lua")
  ModLuaFileAppend("data/scripts/item_spawnlists.lua", "mods/kaleva_koetus/files/scripts/appends/item_spawnlists_b8.lua")
end

function beyond:on_book_generated(entity_id)
  -- log:info("on_book_generated")
  EntityKill(entity_id)
end

return beyond
