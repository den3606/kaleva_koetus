local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")

local EventMessage = {}
EventMessage.message_queue = {}

local function _process_params(event_type, ...)
  local n_params = select("#", ...)
  local params = { ... }

  return { event_type, n_params, params }
end

function EventMessage:queue(...)
  table.insert(self.message_queue, _process_params(...))
end

function EventMessage:fetch()
  local current_queue = self.message_queue
  self.message_queue = {}

  local counter_global = tonumber(GlobalsGetValue("kaleva_queue_counter")) or 0
  for i = 1, counter_global do
    local event_key = "kaleva_queue_item_" .. tostring(i)
    local event_data = GlobalsGetValue(event_key, "")

    local event = json.decode(event_data)
    if event[4] == nil then
      table.insert(current_queue, event)
    else
      local event_type, n_params, param_index, dense_params = unpack(event, 1, 4)
      local params = {}
      for index, index_param in ipairs(param_index) do
        params[index_param] = dense_params[index]
      end
      table.insert(current_queue, { event_type, n_params, params })
    end

    GlobalsSetValue(event_key, "")
  end
  GlobalsSetValue("kaleva_queue_counter", "0")

  local index = 0
  local count = #current_queue

  local n_params
  local params
  local function args_accessor()
    return unpack(params, 1, n_params)
  end

  return function()
    index = index + 1
    if index <= count then
      local event_type
      event_type, n_params, params = unpack(current_queue[index], 1, 3)
      return event_type, args_accessor
    end
    return nil
  end
end

return EventMessage
