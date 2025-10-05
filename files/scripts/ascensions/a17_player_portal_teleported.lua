local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("a17_player_portal_teleported.lua")

function teleported(from_x, from_y, to_x, to_y, portal_teleport)
  if portal_teleport then
    local friend_entity_id = EntityGetWithTag("kk_a17_friend")[1]
    if not friend_entity_id then
      return
    end

    local x, y = EntityGetTransform(friend_entity_id)
    local move_x = to_x - from_x
    local move_y = to_y - from_y

    EntitySetTransform(friend_entity_id, x + move_x, y + move_y)
    EntityApplyTransform(friend_entity_id, x + move_x, y + move_y)
  end
end
