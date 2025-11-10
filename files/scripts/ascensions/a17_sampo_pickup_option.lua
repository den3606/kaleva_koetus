local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local sampo_entity_id = GetUpdatedEntityID()
local item_component_id = EntityGetFirstComponentIncludingDisabled(sampo_entity_id, "ItemComponent")
if ModSettingGet("kaleva_koetus.a20_dead_boss") or ((tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT")) or 0) > 0) then
  ComponentSetValue2(item_component_id, "is_pickable", true)
  local lua_component_id = GetUpdatedComponentID()
  EntityRemoveComponent(sampo_entity_id, lua_component_id)
  return
end

-- NOTE:
-- プレイヤーの座標を取って、そこから200以内にfriendがいなければ、無効化してテキストを出す
local plyer_entity_id = GetPlayerEntity()
if plyer_entity_id == nil or EntityGetIsAlive(plyer_entity_id) == false then
  return
end

local x, y = EntityGetTransform(plyer_entity_id)
local friend_entity_id = EntityGetInRadiusWithTag(x, y, 200, "kk_a17_friend")[1]
local exist_friend = friend_entity_id and friend_entity_id ~= 0

if exist_friend then
  ComponentSetValue2(item_component_id, "is_pickable", true)
else
  ComponentSetValue2(item_component_id, "is_pickable", false)

  local announced = GlobalsGetValue("kaleva_koetus_a17_boss_announced", "false") == "true"
  if not announced then
    local sampo_x, sampo_y = EntityGetTransform(sampo_entity_id)
    if ((x - sampo_x) ^ 2 + (y - sampo_y) ^ 2) ^ 0.5 <= 100 then
      GamePrintImportant("$kaleva_koetus_no_kindness")
      GamePrint("$kaleva_koetus_no_kindness")
      GlobalsSetValue("kaleva_koetus_a17_boss_announced", "true")
    end
  end
end
