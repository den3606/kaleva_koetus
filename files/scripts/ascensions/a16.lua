-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 16
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a16.lua")

function ascension:on_mod_init()
  -- log:info("Always biome")
  ModLuaFileAppend("data/scripts/biome_modifiers.lua", "mods/kaleva_koetus/files/scripts/appends/biome_modifiers.lua")
end

function ascension:on_biome_config_loaded()
  local init_biome_modifiers = dofile_once("data/scripts/biome_modifiers.lua")
  init_biome_modifiers()
end

return ascension
