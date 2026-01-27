local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")

---@class EventSignatures
---@field ENEMY_POST_SPAWN fun(entity_id:number, x:number, y:number)
---@field SHOP_CARD_SPAWN fun(entity_ids:number[], x:number, y:number)
---@field SHOP_WAND_SPAWN fun(entity_ids:number[], x:number, y:number)
---@field NECROMANCER_SPAWN fun(x:number, y:number)
---@field VICTORY fun()
---@field POTION_GENERATED fun(entity_id:number)
---@field BOOK_GENERATED fun(entity_id:number)
---@field GOLD_SPAWN fun(entity_id:number)
---@field SPELL_GENERATED fun(entity_id:number)
---@field BOSS_DIED fun()
---@field NEW_GAME_PLUS_STARTED fun()

---@class EventRemote : EventSignatures
local EventRemote = {}

local function _process_params_dense(event_type, ...)
  local n_params = select("#", ...)
  local params = { ... }

  local is_dense = true
  local n_first = 0
  for i, _ in ipairs(params) do
    n_first = i
  end
  for i = n_first, n_params do
    if params[i] ~= nil then
      is_dense = false
      break
    end
  end

  if is_dense then
    return { event_type, n_params, params }
  end

  local param_index = {}
  local dense_params = {}
  for i = 1, n_params do
    if params[i] ~= nil then
      table.insert(param_index, i)
      table.insert(dense_params, params[i])
    end
  end
  return { event_type, n_params, param_index, dense_params }
end

local function queue_global(...)
  local serialized_data = json.encode(_process_params_dense(...))

  local counter = tonumber(GlobalsGetValue("kaleva_queue_counter")) or 0
  counter = counter + 1

  GlobalsSetValue("kaleva_queue_item_" .. tostring(counter), serialized_data)
  GlobalsSetValue("kaleva_queue_counter", tostring(counter))
end

return setmetatable(EventRemote, {
  __index = function(t, event_type)
    local func = function(...)
      return queue_global(event_type, ...)
    end
    rawset(t, event_type, func)
    return func
  end,
})
