local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local EventArgs = EventDefs.Args
local EventTypes = EventDefs.Types

local EventDispatcher = {}

local function validate_event_type(event_type)
  for _, def_type in pairs(EventTypes) do
    if event_type == def_type then
      return
    end
  end
  GamePrint("[Kaleva Koetus] Unknown event error. Please report to mod developer: " .. event_type)
  error("[EventDispatcher] Unknown event type: " .. event_type)
end

local function validate_event_args(event_type, event_args, expected_args)
  -- Check argument count
  if #event_args < #expected_args then
    print("[Kaleva Koetus] event_args: " .. json.encode(event_args))
    print("[Kaleva Koetus] expected_args: " .. json.encode(expected_args))
    GamePrint("[Kaleva Koetus] Event validation error. Please report to mod developer: " .. event_type)
    error("[Kaleva Koetus] Event validation error: " .. event_type)
  end

  for i, arg_def in ipairs(expected_args) do
    local actual_value = event_args[i]
    local expected_type = arg_def.type

    if type(actual_value) ~= expected_type then
      GamePrint("[Kaleva Koetus] Event type validation error. Please report to mod developer: " .. event_type)
      print(actual_value)
      print("[Kaleva Koetus] actual_value: " .. type(actual_value))
      print("[Kaleva Koetus] expected_type: " .. expected_type)
      error("[Kaleva Koetus] Event type validation error: " .. event_type)
    end
  end
end

local function emit(event_type, callback_object, payload)
  local handler_name = "on_" .. event_type

  if callback_object[handler_name] then
    callback_object[handler_name](callback_object, payload)
  else
    print("[Kaleva Koetus] Handler can not call: " .. handler_name)
  end
end

function EventDispatcher:dispatch(event_type, subscriber, payload)
  local expected_args = EventArgs[event_type]

  validate_event_type(event_type)

  if not expected_args then
    emit(event_type, subscriber, payload)
    return
  end

  validate_event_args(event_type, payload, expected_args)
  emit(event_type, subscriber, payload)
end

return EventDispatcher
