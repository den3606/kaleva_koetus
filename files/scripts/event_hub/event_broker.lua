local _ = dofile_once("data/scripts/lib/coroutines.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local EventPublisher = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_publisher.lua")
local EventDispatcher = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_dispatcher.lua")
local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")

local EventBroker = {}

local log = Logger:new("event_broker.lua")

EventBroker.subscriptions = {}

function EventBroker:init()
  if GlobalsGetValue("kaleva_event_broker_initialized", "0") == "1" then
    log:debug("Already initialized, skipping")
    return
  end

  GlobalsSetValue("kaleva_queue_counter", "0")
  GlobalsSetValue("kaleva_queue_version", "0")
  GlobalsSetValue("kaleva_last_processed", "0")
  GlobalsSetValue("kaleva_event_broker_initialized", "1")
end

function EventBroker:publish_event_sync(source, event_type, ...)
  return EventPublisher:publish(source, event_type, ...)
end

function EventBroker:publish_event_async(source, event_type, ...)
  local args = { ... }
  async(function()
    EventPublisher:publish(source, event_type, unpack(args))
  end)
end

function EventBroker:subscribe_event(event_type, subscriber)
  table.insert(self.subscriptions, {
    event_type = event_type,
    subscriber = subscriber,
  })
end

function EventBroker:flush_event_queue()
  local last_processed = tonumber(GlobalsGetValue("kaleva_last_processed", "0"))
  local current_counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))

  if last_processed >= current_counter then
    return
  end

  for i = last_processed + 1, current_counter do
    local event_key = "kaleva_queue_item_" .. tostring(i)
    local event_data = GlobalsGetValue(event_key, "")

    if event_data == "" then
      log:error("Missing event " .. i .. ", possible race condition")
      return
    end

    local source, event_type, event_args = unpack(json.decode(event_data))

    if not source or not event_type then
      log:error("Event Data is broken")
      return
    end

    for _, subscription in ipairs(EventBroker.subscriptions) do
      if subscription.event_type == event_type then
        log:verbose("Event called from %s / type: %s", source, event_type)
        EventDispatcher:dispatch(subscription.event_type, subscription.subscriber, event_args)
      end
    end

    GlobalsSetValue(event_key, "")
    GlobalsSetValue("kaleva_last_processed", tostring(i))
  end
end

return EventBroker
