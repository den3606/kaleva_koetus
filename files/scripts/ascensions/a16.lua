-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.AscensionTags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a16.lua")

ascension.level = 16
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A16 .. "dummy"

function ascension:on_activate()
  -- log:info("Always biome")
  ModLuaFileAppend("data/scripts/biome_modifiers.lua", "mods/kaleva_koetus/files/scripts/appends/biome_modifiers.lua")
end

function ascension:on_biome_config_loaded()
  local init_biome_modifiers = dofile_once("data/scripts/biome_modifiers.lua")
  init_biome_modifiers()
end

return ascension
