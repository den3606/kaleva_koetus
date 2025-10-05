local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("death_check.lua")

local _death = death
function death(dmg_type, dmg_msg, entity_thats_responsible, drop_items)
  _death(dmg_type, dmg_msg, entity_thats_responsible, drop_items)

  log:debug("dead boss detected")
  EventBroker:publish_event_sync("death_check", EventTypes.BOSS_DIED)
end
