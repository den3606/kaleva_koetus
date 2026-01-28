---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("death_check.lua")

local _death = death
-- selene: allow(unused_variable)

function death(dmg_type, dmg_msg, entity_thats_responsible, drop_items)
  _death(dmg_type, dmg_msg, entity_thats_responsible, drop_items)

  -- log:debug("dead boss detected")
  EventRemote.BOSS_DIED()
end
