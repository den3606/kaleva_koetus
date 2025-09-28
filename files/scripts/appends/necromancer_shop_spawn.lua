local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform(entity_id)

EventBroker:publish_event_async("necromancer_shop_spawn", EventTypes.NECROMANCER_SPAWN, pos_x, pos_y)
