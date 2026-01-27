local EventMessage = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_message.lua")
local EventDispatcher = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_dispatcher.lua")

---@class EventSignaturesLocal : EventSignatures
---@field ENEMY_SPAWN fun(entity_id:number, x:number, y:number, mark_as_processed:function)

---@class EventBroker
local EventBroker = {}
EventBroker._listeners = {}

---@param mode "direct"|"queue"
---@return EventSignaturesLocal
local function create_event_proxy(mode)
  local func_internel
  if mode == "queue" then
    func_internel = function(...)
      return EventMessage:queue(...)
    end
  elseif mode == "direct" then
    func_internel = function(...)
      return EventDispatcher:dispatch(...)
    end
  else
    error("No proxy mode: " .. mode)
  end
  return setmetatable({}, {
    __index = function(t, event_type)
      local func = function(...)
        return func_internel(event_type, ...)
      end
      rawset(t, event_type, func)
      return func
    end,
  })
end

EventBroker.queue = create_event_proxy("queue")
EventBroker.direct = create_event_proxy("direct")

---@return EventSignaturesLocal
local function create_subscribe_proxy()
  return setmetatable({}, {
    __newindex = function(_, event_type, handler)
      EventDispatcher:add_listener(event_type, handler)
    end,
  })
end

EventBroker.on = create_subscribe_proxy()

function EventBroker:flush_event_queue()
  for event_type, get_params in EventMessage:fetch() do
    EventDispatcher:dispatch(event_type, get_params())
  end
end

return EventBroker
