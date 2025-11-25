local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")
local _ = dofile_once("data/scripts/lib/utilities.lua")

local max_distance = 200
local swaying = true

local entity_id = GetUpdatedEntityID()

local radar_x, radar_y = EntityGetFirstHitboxCenter(entity_id)
GlobalsSetValue("kaleva_koetus.a17_friend_last_x", tostring(radar_x))
GlobalsSetValue("kaleva_koetus.a17_friend_last_y", tostring(radar_y))

local x, y = EntityGetTransform(entity_id)
local px, py

local comps = EntityGetComponent(entity_id, "VariableStorageComponent")
if comps ~= nil then
  local owner_id
  local owner_id_comp, target_x_comp, target_y_comp
  for _, v in ipairs(comps) do
    local name = ComponentGetValue2(v, "name")
    if name == "owner_id" then
      owner_id_comp = v
    elseif name == "target_x" then
      target_x_comp = v
    elseif name == "target_y" then
      target_y_comp = v
    end
  end

  if owner_id_comp ~= nil then
    local temp_owner_id = ComponentGetValue2(owner_id_comp, "value_int")
    if temp_owner_id ~= 0 and EntityGetIsAlive(temp_owner_id) == true then
      owner_id = temp_owner_id
      px, py = EntityGetTransform(owner_id)
    end
  end

  if owner_id == nil then
    local temp_owner_id = GetPlayerEntity()
    if temp_owner_id ~= nil and EntityGetIsAlive(temp_owner_id) == true then
      owner_id = temp_owner_id
      px, py = EntityGetTransform(owner_id)
      if owner_id_comp ~= nil then
        ComponentSetValue2(owner_id_comp, "value_int", owner_id)
      end
    end
  end

  if owner_id == nil then
    px = target_x_comp ~= nil and ComponentGetValue2(target_x_comp, "value_float") or x
    py = target_y_comp ~= nil and ComponentGetValue2(target_y_comp, "value_float") or y
  else
    if target_x_comp ~= nil then
      ComponentSetValue2(target_x_comp, "value_float", px)
    end
    if target_y_comp ~= nil then
      ComponentSetValue2(target_y_comp, "value_float", py)
    end
  end
end

-- selene: allow(undefined_variable)
local dist = get_distance(x, y, px, py)
if dist >= max_distance then
  PhysicsSetStatic(entity_id, true)
  return
end

PhysicsSetStatic(entity_id, false)

local cvx, cvy = 0, 0
local physcomp = EntityGetFirstComponent(entity_id, "PhysicsBodyComponent")
if physcomp ~= nil then
  cvx, cvy = PhysicsGetComponentVelocity(entity_id, physcomp)
end

if swaying then
  local arc = GameGetFrameNum() * 0.01 + entity_id
  local length = 12

  px = px + math.cos(arc) * length + math.sin(0 - arc) * length
  py = py - math.sin(arc) * length - math.cos(0 - arc) * length
end

-- selene: allow(undefined_variable)
local dir = get_direction(x, y, px, py)
-- selene: allow(undefined_variable)
dist = math.min(get_distance(x, y, px, py), 32)

local vel_x = 0 - (math.cos(dir) * dist)
local vel_y = 0 - (0 - math.sin(dir) * dist)

if ((x > px) and (cvx > 0)) or ((x < px) and (cvx < 0)) then
  vel_x = vel_x * 4
end

if ((y > py) and (cvy > 0)) or ((y < py) and (cvy < 0)) then
  vel_y = vel_y * 4
end

PhysicsApplyForce(entity_id, vel_x, vel_y)
