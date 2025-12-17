local nxml_helper = {}

---@class error_tracker_state
---@field critical boolean
---@field skip table<string, boolean>

---@param state error_tracker_state
---@param type string
---@param msg string
local function _error_handler(state, type, msg)
  if state.skip[type] == true then
    return
  end
  state.critical = true
  print("parser error: [" .. type .. "] " .. msg)
end

---@param state error_tracker_state
local function _has_critical_error(state)
  return state.critical
end

---@param state error_tracker_state
local function _reset(state)
  state.critical = false
end

---@class error_tracker
---@field error_handler fun(type:string, msg:string)
---@field has_critical_error fun():boolean
---@field reset fun()

---@param errors_to_ignore error_type[]?
---@return error_tracker
function nxml_helper.create_tracker_ignoring(errors_to_ignore)
  ---@type error_tracker_state
  local state = {
    critical = false,
    skip = {},
  }

  if errors_to_ignore ~= nil then
    for _, err_type in ipairs(errors_to_ignore) do
      state.skip[err_type] = true
    end
  end

  return {
    error_handler = function(type, msg)
      _error_handler(state, type, msg)
    end,
    has_critical_error = function()
      return _has_critical_error(state)
    end,
    reset = function()
      _reset(state)
    end,
  }
end

---@param nxml_instance nxml
---@param error_handler fun(type:string, msg:string)
---@param process_func function
function nxml_helper.use_error_handler(nxml_instance, error_handler, process_func)
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

return nxml_helper
