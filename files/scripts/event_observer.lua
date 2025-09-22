-- Event Observer System
-- Handles global event queue processing and dispatching

local _ = dofile_once("data/scripts/lib/coroutines.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
-- local EventTypes = EventDefs.Types -- Not used in this file
local EventArgs = EventDefs.Args
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

-- Legacy function for backward compatibility
function EventObserver:publish_event(source, event_type, ...)
  return self:publish_event_sync(source, event_type, ...)
end

-- Process all pending events from the queue
function EventObserver:process_events()
  local last_processed = tonumber(GlobalsGetValue("kaleva_last_processed", "0"))
  local current_counter = tonumber(GlobalsGetValue("kaleva_queue_counter", "0"))

  -- Process all events from last_processed + 1 to current_counter
  for i = last_processed + 1, current_counter do
    local event_key = "kaleva_queue_item_" .. tostring(i)
    local event_data = GlobalsGetValue(event_key, "")

    if event_data ~= "" then
      self:handle_event(i, event_data)

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

-- Handle individual event
function EventObserver:handle_event(_event_id, event_data)
  -- Parse event: "source|event_type|param1|param2|..."
  local parts = {}
  for part in string.gmatch(event_data, "([^|]+)") do
    table.insert(parts, part)
  end

  if #parts >= 2 then
    local _source = parts[1]
    local event_type = parts[2]

    -- Extract actual event arguments (skip source and event_type)
    local event_args = {}
    for i = 3, #parts do
      table.insert(event_args, parts[i])
    end

    -- Validate event arguments
    local expected_args = EventArgs[event_type]
    if expected_args then
      -- Check argument count
      if #event_args < #expected_args then
        local arg_names = {}
        for _, arg_def in ipairs(expected_args) do
          table.insert(arg_names, arg_def.name)
        end
        local error_msg = string.format(
          "[EventObserver] ERROR: Event '%s' expects %d arguments (%s), got %d",
          event_type,
          #expected_args,
          table.concat(arg_names, ", "),
          #event_args
        )
        print(error_msg)
        GamePrint("Event validation failed: " .. event_type)
      else
        -- Check argument types
        for i, arg_def in ipairs(expected_args) do
          local actual_value = event_args[i]
          local expected_type = arg_def.type

          -- Convert string to expected type if possible
          if expected_type == "number" and type(actual_value) == "string" then
            local converted = tonumber(actual_value)
            if converted then
              event_args[i] = converted
            else
              local error_msg = string.format(
                "[EventObserver] ERROR: Event '%s' argument '%s' (index %d) cannot be converted to %s: '%s'",
                event_type,
                arg_def.name,
                i,
                expected_type,
                tostring(actual_value)
              )
              print(error_msg)
              GamePrint("Event type validation failed: " .. event_type)
            end
          elseif type(actual_value) ~= expected_type then
            local error_msg = string.format(
              "[EventObserver] ERROR: Event '%s' argument '%s' (index %d) expected %s, got %s: '%s'",
              event_type,
              arg_def.name,
              i,
              expected_type,
              type(actual_value),
              tostring(actual_value)
            )
            print(error_msg)
            GamePrint("Event type validation failed: " .. event_type)
          end
        end
      end
    end

    -- Dispatch to AscensionManager with event arguments only
    local AscensionManager = dofile_once("mods/kaleva_koetus/files/scripts/ascension_manager.lua")
    AscensionManager:dispatch_event(event_type, event_args)
  end
end

return EventObserver
