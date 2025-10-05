dofile_once("data/scripts/lib/utilities.lua")

local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity_id)
local px, py = x, y
local owner_id = 0

local comps = EntityGetComponent(entity_id, "VariableStorageComponent")
local swaying = true

if comps ~= nil then
  for i, v in ipairs(comps) do
    local name = ComponentGetValue2(v, "name")

    if name == "owner_id" then
      owner_id = ComponentGetValue2(v, "value_int")
      px, py = EntityGetTransform(owner_id)

      if (px == nil) or (py == nil) then
        px, py = x, y
      end
    end
  end
end

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

local dir = get_direction(x, y, px, py)
local dist = math.min(get_distance(x, y, px, py), 32)

local vel_x = 0 - (math.cos(dir) * dist)
local vel_y = 0 - (0 - math.sin(dir) * dist)

if ((x > px) and (cvx > 0)) or ((x < px) and (cvx < 0)) then
  vel_x = vel_x * 4
end

if ((y > py) and (cvy > 0)) or ((y < py) and (cvy < 0)) then
  vel_y = vel_y * 4
end

PhysicsApplyForce(entity_id, vel_x, vel_y)

if owner_id ~= 0 then
  x, y = EntityGetTransform(entity_id)
  local ox, oy = EntityGetTransform(owner_id)
  dist = math.abs(x - ox) + math.abs(y - oy)

  if dist > 900 then
  end
end
