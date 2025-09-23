local EventTransformer = {}

function EventTransformer:parse_event_data(event_data)
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

function EventTransformer:convert_arg_types(event_type, event_args, expected_args)
  for i, arg_def in ipairs(expected_args) do
    local actual_value = event_args[i]
    local expected_type = arg_def.type

    if expected_type == "number" and type(actual_value) == "string" then
      local converted = tonumber(actual_value)
      if converted then
        event_args[i] = converted
      else
        error("[Kaleva Koetus] Event type conversion error: " .. event_type)
        GamePrint("[Kaleva Koetus] Event type conversion error. Please report to mod developer: " .. event_type)
        return false, event_args
      end
    end
  end

  return true, event_args
end

return EventTransformer
