local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("book.lua")

log:debug("Book generate detected")
local entity_id = GetUpdatedEntityID()
EventBroker:publish_event_async("book", EventTypes.BOOK_GENERATED, entity_id)
