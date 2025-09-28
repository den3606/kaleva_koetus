local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("potion.lua")

local _init = init

-- selene: allow(unused_variable)
function init(entity_id)
  _init(entity_id)

  log:debug("Potion generate detected")
  EventBroker:publish_event_async("potion", EventTypes.POTION_GENERATED, entity_id)
end
