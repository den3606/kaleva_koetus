local _ = dofile_once("data/scripts/lib/utilities.lua")

local entity_id = GetUpdatedEntityID()
if ModSettingGet("kaleva_koetus.a20_dead_boss") or ((tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT")) or 0) > 0) then
  local lua_component_id = GetUpdatedComponentID()
  EntityRemoveComponent(entity_id, lua_component_id)
  return
end

local pos_x, pos_y = EntityGetTransform(entity_id)
pos_y = pos_y - 4 -- offset to middle of character

local range = 1000
local indicator_distance = 40

local enemy_x, enemy_y

local friend_id = EntityGetClosestWithTag(pos_x, pos_y, "kk_a17_friend")
if friend_id ~= nil and friend_id ~= 0 then
  enemy_x, enemy_y = EntityGetFirstHitboxCenter(friend_id)
else
  enemy_x = tonumber(GlobalsGetValue("kaleva_koetus.a17_friend_last_x")) or pos_x
  enemy_y = tonumber(GlobalsGetValue("kaleva_koetus.a17_friend_last_y")) or pos_y
end

local dir_x = enemy_x - pos_x
local dir_y = enemy_y - pos_y
-- selene: allow(undefined_variable)
local distance = get_magnitude(dir_x, dir_y)

local indicator_x = 0
local indicator_y = 0

-- selene: allow(undefined_variable)
if is_in_camera_bounds(enemy_x, enemy_y, -4) then
  indicator_x = enemy_x
  indicator_y = enemy_y - 3
else
  -- selene: allow(undefined_variable)
  dir_x, dir_y = vec_normalize(dir_x, dir_y)
  indicator_x = pos_x + dir_x * indicator_distance
  indicator_y = pos_y + dir_y * indicator_distance
end

-- display sprite based on proximity
if distance > range * 0.8 then
  GameCreateSpriteForXFrames(
    "mods/kaleva_koetus/tmp/a17/data/particles/radar_enemy_faint.png",
    indicator_x,
    indicator_y,
    true,
    0,
    0,
    1,
    true
  )
elseif distance > range * 0.5 then
  GameCreateSpriteForXFrames(
    "mods/kaleva_koetus/tmp/a17/data/particles/radar_enemy_medium.png",
    indicator_x,
    indicator_y,
    true,
    0,
    0,
    1,
    true
  )
else
  GameCreateSpriteForXFrames(
    "mods/kaleva_koetus/tmp/a17/data/particles/radar_enemy_strong.png",
    indicator_x,
    indicator_y,
    true,
    0,
    0,
    1,
    true
  )
end
