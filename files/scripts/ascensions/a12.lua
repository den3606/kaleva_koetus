local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a12.lua")

ascension.level = 12
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A12 .. "unused"

function ascension:on_activate()
  log:info("Temple Alter's water withered")
end

function ascension:on_world_initialized()
  -- NOTE:
  -- Check appends temple_altar_left.lua / temple_altar.lua
  log:debug("load a12 override")
  GlobalsSetValue(AscensionTags.A12 .. "override_pixel_scene", "1")
end

return ascension
