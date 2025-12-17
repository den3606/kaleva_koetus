local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local entity_id = GetUpdatedEntityID()
if entity_id == 0 then
  return
end

EventBroker:publish_event_async("potion_spawn", EventTypes.POTION_GENERATED, entity_id)
