local _ = dofile_once("data/scripts/lib/coroutines.lua")

---@class Queue
---@field private buffer any[]
---@field private capacity number
---@field private head number
---@field private tail number
---@field private count number
local Queue = {}
Queue.__index = Queue

---@param capacity number
---@return Queue?
function Queue.new(capacity)
  if capacity < 1 then
    return nil
  end

  local self = setmetatable({
    buffer = {},
    capacity = capacity,
    head = 0,
    tail = 0,
    count = 0,
  }, Queue)

  return self
end

---@param item any
---@return boolean success
function Queue:push(item)
  if self.count >= self.capacity then
    return false
  end

  local idx = self.tail + 1
  self.buffer[idx] = item

  self.tail = (self.tail + 1) % self.capacity
  self.count = self.count + 1

  return true
end

---@return any item
function Queue:pop()
  if self.count == 0 then
    return nil
  end

  local idx = self.head + 1
  local item = self.buffer[idx]

  self.buffer[idx] = nil

  self.head = (self.head + 1) % self.capacity
  self.count = self.count - 1

  return item
end

---@return any item
function Queue:front()
  if self.count == 0 then
    return nil
  end

  return self.buffer[self.head + 1]
end

function Queue:clear()
  if self.count == 0 then
    return
  end

  self.buffer = {}
  self.head = 0
  self.tail = 0
  self.count = 0
end

---@return number
function Queue:size()
  return self.count
end

---@param entity_id number?
---@return boolean
local function is_entity_really_alive(entity_id)
  if entity_id == nil then
    return false
  end

  if EntityGetIsAlive(entity_id) == false then
    return false
  end

  local x, y = EntityGetTransform(entity_id)
  local real_entities = EntityGetInRadius(x, y, 1)
  for _, real_entity_id in ipairs(real_entities) do
    if real_entity_id == entity_id then
      return true
    end
  end

  return false
end

local SHADOW_DELAY_FRAME_NUM = 30

local player_shadow_entity_id
local player_pos_buffer = Queue.new(SHADOW_DELAY_FRAME_NUM + 1)
if player_pos_buffer == nil then
  return
end

async_loop(function()
  local entity_id = GetUpdatedEntityID()
  local root_entity_id = EntityGetRootEntity(entity_id)

  local is_invisible

  local invisibility_effect_component_id = GameGetGameEffect(root_entity_id, "INVISIBILITY")
  if invisibility_effect_component_id == 0 then
    is_invisible = false
  else
    is_invisible = ComponentGetValue2(invisibility_effect_component_id, "mInvisible")
  end

  if is_invisible == false then
    if is_entity_really_alive(player_shadow_entity_id) == true then
      EntityKill(player_shadow_entity_id)
    end
    player_shadow_entity_id = nil
    player_pos_buffer:clear()
  else
    local x, y = EntityGetFirstHitboxCenter(root_entity_id)
    if is_entity_really_alive(player_shadow_entity_id) == false then
      player_shadow_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/invisibility_player_shadow.xml", x, y)
    end

    player_pos_buffer:push({ x, y })
    if player_pos_buffer:size() > SHADOW_DELAY_FRAME_NUM then
      local buffered_pos = player_pos_buffer:pop()
      x, y = unpack(buffered_pos)
      EntitySetTransform(player_shadow_entity_id, x, y)
    end
  end

  wait(0)
end)
