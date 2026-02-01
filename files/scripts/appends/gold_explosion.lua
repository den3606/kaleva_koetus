---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

local entity_id = GetUpdatedEntityID()
EventRemote.GOLD_SPAWN(entity_id)
