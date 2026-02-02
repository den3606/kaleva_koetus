---@class EventRemote
local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

-- selene: allow(undefined_variable)
local _IMPL_remove_all_perks = IMPL_remove_all_perks

local function post_IMPL_remove_all_perks(player_id, ...)
  if player_id ~= nil then
    EventRemote.PERK_REMOVE_ALL(player_id)
  end
  return ...
end

-- selene: allow(unused_variable)
function IMPL_remove_all_perks(player_id, ...)
  return post_IMPL_remove_all_perks(player_id, _IMPL_remove_all_perks(player_id, ...))
end
