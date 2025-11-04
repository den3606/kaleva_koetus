local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local entity_id = GetUpdatedEntityID()
EventBroker:publish_event_sync("game_helpers.load_gold_entity", EventTypes.GOLD_SPAWN, entity_id)
