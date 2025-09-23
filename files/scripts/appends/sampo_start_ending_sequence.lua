-- Append to sampo_start_ending_sequence
-- This file is executed when the victory condition is met (picking up Sampo)

-- Make sure we only process victory once per run
if GlobalsGetValue("kaleva_koetus_victory_processed", "0") == "1" then
  return
end

GlobalsSetValue("kaleva_koetus_victory_processed", "1")

-- Load event system and send victory event
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

print("[Kaleva Koetus] Victory detected - Sampo ending sequence started")
EventBroker:publish_event_sync("sampo_start_ending_sequence", EventTypes.VICTORY)
