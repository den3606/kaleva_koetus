-- Append to sampo_start_ending_sequence
-- This file is executed when the victory condition is met (picking up Sampo)

if GlobalsGetValue("kaleva_koetus_victory_processed", "0") == "1" then
  return
end

GlobalsSetValue("kaleva_koetus_victory_processed", "1")

---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("sampo_start_ending_sequence.lua")

-- log:debug("Victory detected - Sampo ending sequence started")
EventRemote.VICTORY()
