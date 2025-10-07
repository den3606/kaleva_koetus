local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("fungal_shift_curse_released.lua")

-- log:debug("fungal shift curse called")

EventBroker:publish_event_async("fungal_shift_curse_released", EventTypes.FUNGAL_SHIFT_CURSE_RELEASED)
