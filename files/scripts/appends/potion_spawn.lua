---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local entity_id = GetUpdatedEntityID()
if entity_id == 0 then
  return
end

EventRemote.POTION_GENERATED(entity_id)
