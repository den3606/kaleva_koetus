-- Append to sampo_start_ending_sequence
-- This file is executed when the victory condition is met (picking up Sampo)

if GlobalsGetValue("kaleva_koetus_victory_processed", "0") == "1" then
  return
end

GlobalsSetValue("kaleva_koetus_victory_processed", "1")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local Logger = KalevaLogger or dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:bind("Victory")

log:info("Victory detected - Sampo ending sequence started")
EventBroker:publish_event_sync("sampo_start_ending_sequence", EventTypes.VICTORY)
