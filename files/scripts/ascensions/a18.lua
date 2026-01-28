-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 18
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a18.lua")

function ascension:on_mod_init()
  -- log:debug("Decrease hp")
  ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/kaleva_koetus/files/scripts/appends/heart_fullhp_temple.lua")
end

return ascension
