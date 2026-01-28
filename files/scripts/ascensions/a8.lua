-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 8
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a8.lua")

function ascension:on_mod_init()
  -- log:info("Preventing tablet spawns")
end

function ascension:on_book_generated(entity_id)
  -- log:info("on_book_generated")
  EntityKill(entity_id)
end

return ascension
