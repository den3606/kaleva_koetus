local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local reduce_potion = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a7_reduce_potion_capacity.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("a7.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 7
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A7 .. EventTypes.POTION_GENERATED

function ascension:on_activate()
  -- log:info("Potion volume reduced to %.0f%%", MATERIAL_SCALE * 100)
end

function ascension:on_potion_generated(payload)
  -- log:info("on_potion_generated")
  local potion_entity_id = tonumber(payload[1])
  -- log:debug("potion_entity: " .. potion_entity_id)
  if potion_entity_id == nil or potion_entity_id == 0 then
    return
  end

  if EntityGetIsAlive(potion_entity_id) == false then
    return
  end

  reduce_potion(potion_entity_id)
end

return ascension
