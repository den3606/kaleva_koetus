local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local sampo_entity_id = GetUpdatedEntityID()
-- プレイヤーの座標を取って、そこから200以内にfrinedがいなければ、無効化してテキストを出す
local plyer_entity_id = GetPlayerEntity()
local x, y = EntityGetTransform(plyer_entity_id)
local friend_entity_id = EntityGetInRadiusWithTag(x, y, 200, "kk_a17_friend")[1]
local exist_friend = friend_entity_id and friend_entity_id ~= 0

local item_component_id = EntityGetFirstComponentIncludingDisabled(sampo_entity_id, "ItemComponent")
if exist_friend then
  ComponentSetValue2(item_component_id, "is_pickable", true)
else
  local announced = GlobalsGetValue("kaleva_koetus_a17_boss_announced", "false") == "true"
  if not announced then
    GamePrintImportant("$kaleva_koetus_no_kindness")
    GamePrint("$kaleva_koetus_no_kindness")
    GlobalsSetValue("kaleva_koetus_a17_boss_announced", "true")
  end

  ComponentSetValue2(item_component_id, "is_pickable", false)
end
