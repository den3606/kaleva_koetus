local EventTransformer = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_transformer.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventArgs = EventDefs.Args
local EventTypes = EventDefs.Types

local EventDispatcher = {}

local function _validate_args(event_type, event_args, expected_args)
  -- Check argument count
  if #event_args < #expected_args then
    error("[Kaleva Koetus] Event validation error: " .. event_type)
    GamePrint("[Kaleva Koetus] Event validation error. Please report to mod developer: " .. event_type)
    return false
  end

  -- Check argument types (after conversion)
  for i, arg_def in ipairs(expected_args) do
    local actual_value = event_args[i]
    local expected_type = arg_def.type

    if type(actual_value) ~= expected_type then
      error("[Kaleva Koetus] Event type validation error: " .. event_type)
      GamePrint("[Kaleva Koetus] Event type validation error. Please report to mod developer: " .. event_type)
      return false
    end
  end

  return true
end

local function emit(listener, event_type, payload)
  local handler_name = "on_" .. event_type

  if listener[handler_name] then
    listener[handler_name](listener, payload)
  end
end

function EventDispatcher.dispatch(listener, event_type, payload)
  -- Step 2: Validate event type
  local is_valid_event_type = false
  for _, valid_type in pairs(EventTypes) do
    if event_type == valid_type then
      is_valid_event_type = true
      break
    end
  end

  if not is_valid_event_type then
    error("[EventDispatcher] Unknown event type: " .. event_type)
    GamePrint("[Kaleva Koetus] Unknown event error. Please report to mod developer: " .. event_type)
    return
  end

  -- Step 3: Get expected arguments definition
  local expected_args = EventArgs[event_type]
  if not expected_args then
    emit(listener, event_type, payload)
    return
  end

  -- Step 4: Convert argument types
  local convert_success, converted_args = EventTransformer:convert_arg_types(event_type, payload, expected_args)
  if not convert_success then
    return
  end

  -- Step 5: Validate arguments
  local validate_success = _validate_args(event_type, converted_args, expected_args)
  if not validate_success then
    return
  end

  emit(listener, event_type, payload)
end

return EventDispatcher
