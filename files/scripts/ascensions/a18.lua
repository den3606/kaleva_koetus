-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.AscensionTags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a18.lua")

ascension.level = 18
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A18

function ascension:on_activate()
  -- log:debug("Decrease hp")
  ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/kaleva_koetus/files/scripts/appends/heart_fullhp_temple.lua")
end

return ascension
