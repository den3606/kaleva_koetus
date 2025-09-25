local Logger = {}

Logger._levels = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4,
  TRACE = 5,
}

Logger._level = "INFO"
Logger._prefix = "[Kaleva Koetus]"

local function normalize_level(level)
  if not level then
    return nil
  end

  if type(level) ~= "string" then
    level = tostring(level)
  end

  return string.upper(level)
end

function Logger:set_level(level)
  local normalized = normalize_level(level)
  if normalized and self._levels[normalized] then
    self._level = normalized
  else
    print(string.format("%s[WARN][Logger] Unknown log level '%s', keep %s", self._prefix, tostring(level), self._level))
  end
end

function Logger:get_level()
  return self._level
end

function Logger:set_prefix(prefix)
  if prefix and prefix ~= "" then
    self._prefix = prefix
  end
end

function Logger:_should_log(level)
  local normalized = normalize_level(level)
  if not normalized then
    return false
  end

  local target = self._levels[normalized]
  local current = self._levels[self._level]

  if not target or not current then
    return false
  end

  return target <= current
end

local function format_message(message, ...)
  if select("#", ...) > 0 and type(message) == "string" then
    local ok, result = pcall(string.format, message, ...)
    if ok then
      return result
    end

    return string.format("%s (format failed: %s)", message, tostring(result))
  end

  if message == nil then
    return "(nil)"
  end

  return tostring(message)
end

function Logger:_emit(level, tag, message, ...)
  if not self:_should_log(level) then
    return
  end

  local resolved_tag = tag or "General"
  local resolved_message = format_message(message, ...)

  local output = string.format("%s[%s][%s] %s", self._prefix, level, resolved_tag, resolved_message)

  if level == "ERROR" then
    error(output, 2)
  else
    print(output)
  end
end

function Logger:trace(tag, message, ...)
  self:_emit("TRACE", tag, message, ...)
end

function Logger:debug(tag, message, ...)
  self:_emit("DEBUG", tag, message, ...)
end

function Logger:info(tag, message, ...)
  self:_emit("INFO", tag, message, ...)
end

function Logger:warn(tag, message, ...)
  self:_emit("WARN", tag, message, ...)
end

function Logger:error(tag, message, ...)
  self:_emit("ERROR", tag, message, ...)
end

function Logger:bind(tag)
  local bound_tag = tag or "General"

  return {
    trace = function(_, message, ...)
      Logger:trace(bound_tag, message, ...)
    end,
    debug = function(_, message, ...)
      Logger:debug(bound_tag, message, ...)
    end,
    info = function(_, message, ...)
      Logger:info(bound_tag, message, ...)
    end,
    warn = function(_, message, ...)
      Logger:warn(bound_tag, message, ...)
    end,
    error = function(_, message, ...)
      Logger:error(bound_tag, message, ...)
    end,
  }
end

return Logger
