---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("book.lua")

-- log:debug("Book generate detected")
local entity_id = GetUpdatedEntityID()
EventRemote.BOOK_GENERATED(entity_id)
