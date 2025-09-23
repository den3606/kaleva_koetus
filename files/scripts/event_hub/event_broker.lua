local _ = dofile_once("data/scripts/lib/coroutines.lua")

-- Load Event Handler module
local EventPublisher = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_publisher.lua")
local EventDispatcher = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_dispatcher.lua")
local EventTransformer = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_transformer.lua")

local EventBroker = {}

---@class EventListenerEntry
---@field event_type string
---@field listener table<string, fun(self: table, ...)>
---@type EventListenerEntry[]
EventBroker.listener = {}

function EventBroker:init()
  -- Check if already initialized
  if GlobalsGetValue("kaleva_event_broker_initialized", "0") == "1" then
    print("[EventBroker] Already initialized, skipping")
    return
  end

  -- Initialize queue counters
  GlobalsSetValue("kaleva_queue_counter", "0")
  GlobalsSetValue("kaleva_queue_version", "0")
  GlobalsSetValue("kaleva_last_processed", "0")
  GlobalsSetValue("kaleva_event_broker_initialized", "1")
end

-- Synchronous event publishing
function EventBroker:publish_event_sync(source, event_type, ...)
  return EventPublisher.publish(source, event_type, ...)
end

-- Asynchronous event publishing
function EventBroker:publish_event_async(source, event_type, ...)
  local args = { ... }
  async(function()
    EventPublisher.publish(source, event_type, unpack(args))
  end)
end

function EventBroker:subscribe_event(event_type, listener)
  table.insert(self.listener, {
    event_type = event_type,
    listener = listener,
  })
end

local function dispatch(event_data)
  local source, event_type, event_args = EventTransformer:parse_event_data(event_data)
  if not source or not event_type then
    error("[EventBroker] Event Data is broken")
    return
  end

  print("[EventBroker] Event called from " .. source)

  for _, entry in ipairs(EventBroker.listener) do
    if entry.event_type == event_type then
      EventDispatcher.dispatch(entry.listener, event_type, event_args)
    end
  end
end

-- Flush all pending events from the queue
function EventBroker:flush_event_queue()
  local last_processed = tonumber(GlobalsGetValue("kaleva_last_processed", "0"))
  local current_counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))

  -- Early return if no new events
  local no_have_event = last_processed >= current_counter
  if no_have_event then
    return
  end

  -- Process all events from last_processed + 1 to current_counter
  for i = last_processed + 1, current_counter do
    local event_key = "kaleva_queue_item_" .. tostring(i)
    local event_data = GlobalsGetValue(event_key, "")

    if event_data ~= "" then
      dispatch(event_data)

      GlobalsSetValue(event_key, "")
      GlobalsSetValue("kaleva_last_processed", tostring(i))
    else
      error("[EventBroker] Missing event " .. i .. ", possible race condition")
    end
  end
end

return EventBroker
