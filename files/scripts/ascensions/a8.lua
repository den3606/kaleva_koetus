-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.AscensionTags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a8.lua")

ascension.level = 8
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A8 .. EventTypes.BOOK_GENERATED

function ascension:on_activate()
  -- log:info("Preventing tablet spawns")
end

function ascension:on_book_generated(payload)
  -- log:info("on_book_generated")
  local book_entity_id = tonumber(payload[1])
  -- log:debug("book_entity_id: " .. book_entity_id)
  EntityKill(book_entity_id)
end

return ascension
