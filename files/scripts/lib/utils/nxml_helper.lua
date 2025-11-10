local NxmlHelper = {}

local ignorable_errors = {
  duplicate_attribute = true,
  missing_equals_sign = true,
  missing_attribute_value = true,
}

---@class error_tracker
---@field error_handler fun(type:string, msg:string)
---@field has_critical_error fun()
---@field reset fun()

---@return error_tracker
function NxmlHelper.create_error_tracker()
  local error_tracker = {}
  local critical_error_encountered = false

  function error_tracker.error_handler(type, msg)
    if ignorable_errors[type] == true then
      return
    end
    critical_error_encountered = true
    print("parser error: [" .. type .. "] " .. msg)
  end

  function error_tracker.has_critical_error()
    return critical_error_encountered
  end

  function error_tracker.reset()
    critical_error_encountered = false
  end

  return error_tracker
end

function NxmlHelper.using_error_handler(nxml_instance, error_handler, process_func)
  local old_error_handler = nxml_instance.error_handler
  nxml_instance.error_handler = error_handler

  local results = { pcall(process_func) }

  nxml_instance.error_handler = old_error_handler

  if results[1] == true then
    return unpack(results, 2)
  else
    error(results[2])
  end
end

return NxmlHelper
