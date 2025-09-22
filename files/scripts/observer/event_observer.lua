local _ = dofile_once("data/scripts/lib/coroutines.lua")

-- Load Event Handler module
local EventHandler = dofile_once("mods/kaleva_koetus/files/scripts/observer/_event_handler.lua")

-- Internal helper for publishing events
local function _publish_event(source, event_type, ...)
  local params = { ... }

  -- Build event data: "source|event_type|param1|param2|..."
  local event_parts = { source, event_type }
  for _, param in ipairs(params) do
    table.insert(event_parts, tostring(param))
  end

  local event_data = table.concat(event_parts, "|")

  -- Optimistic locking with retry
  local retry = 5
  while retry > 0 do
    local counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))
    local version = tonumber(GlobalsGetValue("kaleva_queue_version", "0"))

    -- Calculate new values
    local new_counter = counter + 1
    local new_version = version + 1

    -- Check if version is still the same (no other writer)
    if tonumber(GlobalsGetValue("kaleva_queue_version", "0")) == version then
      -- Atomic-like write sequence
      GlobalsSetValue("kaleva_queue_item_" .. tostring(new_counter), event_data)
      GlobalsSetValue("kaleva_queue_counter", tostring(new_counter))
      GlobalsSetValue("kaleva_queue_version", tostring(new_version))

      print("[EventObserver] Queued event " .. new_counter .. " (v" .. new_version .. "): " .. event_data)
      return true -- Success
    end

    -- Version changed, retry
    retry = retry - 1
    print("[EventObserver] Queue contention, retrying... (" .. retry .. " left)")
  end

  print("[EventObserver] ERROR: Failed to queue event after retries: " .. event_data)
  return false
end

local EventObserver = {}

-- Initialize observer
function EventObserver:init()
  -- Check if already initialized
  if GlobalsGetValue("kaleva_observer_initialized", "0") == "1" then
    print("[EventObserver] Already initialized, skipping")
    return
  end

  -- Initialize queue counters
  GlobalsSetValue("kaleva_queue_counter", "0")
  GlobalsSetValue("kaleva_queue_version", "0")
  GlobalsSetValue("kaleva_last_processed", "0")
  GlobalsSetValue("kaleva_observer_initialized", "1")

  print("[EventObserver] Initialized")
end

-- Synchronous event publishing
function EventObserver:publish_event_sync(source, event_type, ...)
  return _publish_event(source, event_type, ...)
end

-- Asynchronous event publishing
function EventObserver:publish_event_async(source, event_type, ...)
  local args = { ... }
  async(function()
    _publish_event(source, event_type, unpack(args))
  end)
end

-- Flush all pending events from the queue
function EventObserver:flush_event_queue()
  local last_processed = tonumber(GlobalsGetValue("kaleva_last_processed", "0"))
  local current_counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))

  -- Process all events from last_processed + 1 to current_counter
  for i = last_processed + 1, current_counter do
    local event_key = "kaleva_queue_item_" .. tostring(i)
    local event_data = GlobalsGetValue(event_key, "")

    if event_data ~= "" then
      print("[EventObserver] Processing event " .. i .. ": " .. event_data)
      EventHandler.handle(i, event_data)
      print("[EventObserver] Event " .. i .. " processing completed")

      -- Clear processed event to free memory
      GlobalsSetValue(event_key, "")
    else
      print("[EventObserver] Warning: Missing event " .. i .. ", possible race condition")
    end
  end

  -- Update last processed counter
  if current_counter > last_processed then
    GlobalsSetValue("kaleva_last_processed", tostring(current_counter))
  end
end

return EventObserver
