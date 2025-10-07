local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("fungal_shift.lua")

local _fungal_shift = fungal_shift

-- selene: allow(unused_variable)
function fungal_shift(entity, x, y, debug_no_limits)
  _fungal_shift(entity, x, y, debug_no_limits)

  -- log:debug("fungal shift detected")
  EventBroker:publish_event_async("fungal_shift", EventTypes.FUNGAL_SHIFTED)
end
