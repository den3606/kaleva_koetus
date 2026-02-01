---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform(entity_id)

EventRemote.NECROMANCER_SPAWN(pos_x, pos_y)
