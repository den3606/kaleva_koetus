local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventArgs = EventDefs.Args
local EventTypes = EventDefs.Types

-- Parse event data string into components
local function _parse_event_data(event_data)
  local parts = {}
  for part in string.gmatch(event_data, "([^|]+)") do
    table.insert(parts, part)
  end

  if #parts < 2 then
    return nil, nil, nil
  end

  local source = parts[1]
  local event_type = parts[2]
  local event_args = {}

  for i = 3, #parts do
    table.insert(event_args, parts[i])
  end

  return source, event_type, event_args
end

-- Generate validation error message
local function _create_validation_error_msg(event_type, error_type, details)
  local base_msg = "[EventObserver] ERROR: Event '" .. event_type .. "' "

  if error_type == "arg_count" then
    return string.format(
      "%sexpects %d arguments (%s), got %d",
      base_msg,
      details.expected_count,
      table.concat(details.arg_names, ", "),
      details.actual_count
    )
  elseif error_type == "type_conversion" then
    return string.format(
      "%sargument '%s' (index %d) cannot be converted to %s: '%s'",
      base_msg,
      details.arg_name,
      details.index,
      details.expected_type,
      details.value
    )
  elseif error_type == "type_mismatch" then
    return string.format(
      "%sargument '%s' (index %d) expected %s, got %s: '%s'",
      base_msg,
      details.arg_name,
      details.index,
      details.expected_type,
      details.actual_type,
      details.value
    )
  end

  return base_msg .. "unknown validation error"
end

-- Convert argument types (string to number, etc.)
local function _convert_arg_types(event_type, event_args, expected_args)
  for i, arg_def in ipairs(expected_args) do
    local actual_value = event_args[i]
    local expected_type = arg_def.type

    if expected_type == "number" and type(actual_value) == "string" then
      local converted = tonumber(actual_value)
      if converted then
        event_args[i] = converted
      else
        local error_msg = _create_validation_error_msg(event_type, "type_conversion", {
          arg_name = arg_def.name,
          index = i,
          expected_type = expected_type,
          value = tostring(actual_value),
        })

        error(error_msg)
        GamePrint("[Kaleva Koetus] Event type conversion error. Please report to mod developer: " .. event_type)
        return false, event_args
      end
    end
  end

  return true, event_args
end

-- Validate event arguments (count and types)
local function _validate_args(event_type, event_args, expected_args)
  -- Check argument count
  if #event_args < #expected_args then
    local arg_names = {}
    for _, arg_def in ipairs(expected_args) do
      table.insert(arg_names, arg_def.name)
    end

    local error_msg = _create_validation_error_msg(event_type, "arg_count", {
      expected_count = #expected_args,
      arg_names = arg_names,
      actual_count = #event_args,
    })

    error(error_msg)
    GamePrint("[Kaleva Koetus] Event validation error. Please report to mod developer: " .. event_type)
    return false
  end

  -- Check argument types (after conversion)
  for i, arg_def in ipairs(expected_args) do
    local actual_value = event_args[i]
    local expected_type = arg_def.type

    if type(actual_value) ~= expected_type then
      local error_msg = _create_validation_error_msg(event_type, "type_mismatch", {
        arg_name = arg_def.name,
        index = i,
        expected_type = expected_type,
        actual_type = type(actual_value),
        value = tostring(actual_value),
      })

      error(error_msg)
      GamePrint("[Kaleva Koetus] Event type validation error. Please report to mod developer: " .. event_type)
      return false
    end
  end

  return true
end

-- Load dispatchers
local AscensionDispatcher = dofile_once("mods/kaleva_koetus/files/scripts/pubsubdispatchers/ascension_dispatcher.lua")

-- Dispatch event to appropriate managers
local function _dispatch_event(event_type, event_args)
  AscensionDispatcher.dispatch(event_type, event_args)
end

local EventHandler = {}

-- Handle individual event from queue (main function)
-- @param queue_index: The position of this event in the processing queue (for debugging/logging)
-- @param event_data: The raw event data string to be processed
function EventHandler.handle(_queue_index, event_data)
  -- Step 1: Parse event data
  local source, event_type, event_args = _parse_event_data(event_data)
  if not source or not event_type then
    return
  end

  -- Step 2: Validate event type
  local is_valid_event_type = false
  for _, valid_type in pairs(EventTypes) do
    if event_type == valid_type then
      is_valid_event_type = true
      break
    end
  end

  if not is_valid_event_type then
    error("[EventHandler] Unknown event type: " .. event_type)
    GamePrint("[Kaleva Koetus] Unknown event error. Please report to mod developer: " .. event_type)
    return
  end

  -- Step 3: Get expected arguments definition
  local expected_args = EventArgs[event_type]
  if not expected_args then
    _dispatch_event(event_type, event_args)
    return
  end

  -- Step 4: Convert argument types
  local convert_success, converted_args = _convert_arg_types(event_type, event_args, expected_args)
  if not convert_success then
    return
  end

  -- Step 5: Validate arguments
  local validate_success = _validate_args(event_type, converted_args, expected_args)
  if not validate_success then
    return
  end

  -- Step 6: Dispatch to appropriate manager
  _dispatch_event(event_type, converted_args)
end

return EventHandler
