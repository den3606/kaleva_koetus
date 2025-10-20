-- selene: allow(unused_variable)
function teleported(from_x, from_y, to_x, to_y, portal_teleport)
  if portal_teleport then
    local friend_entity_id = EntityGetWithTag("kk_a17_friend")[1]
    if not friend_entity_id then
      return
    end

    -- 200px以内にfriendがいなければ、テレポート処理を防ぐ
    local plyer_entity_id = GetPlayerEntity()
    local x, y = EntityGetTransform(plyer_entity_id)
    local friend_entity_id = EntityGetInRadiusWithTag(x, y, 200, "kk_a17_friend")[1]
    local exist_friend = friend_entity_id and friend_entity_id ~= 0

    if not exist_friend then
      return
    end

    local x, y = EntityGetTransform(friend_entity_id)
    local move_x = to_x - from_x
    local move_y = to_y - from_y

    EntitySetTransform(friend_entity_id, x + move_x, y + move_y)
    EntityApplyTransform(friend_entity_id, x + move_x, y + move_y)
  end
end
