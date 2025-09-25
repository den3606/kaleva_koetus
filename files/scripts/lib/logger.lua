local Logger = {}
Logger.__index = Logger

local LEVELS = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4,
  VERBOSE = 5,
}

local DEFAULTS = {
  level = "INFO",
  prefix = "Kaleva Koetus",
  tag = "General",
  level_setting_key = "kaleva_koetus.log_level",
}

Logger._levels = LEVELS

local function normalize_level(level)
  if not level then
    return nil
  end

  if type(level) ~= "string" then
    level = tostring(level)
  end

  return string.upper(level)
end

local function resolve_level_name(level)
  if level == nil then
    return nil
  end

  if type(level) == "string" then
    local normalized = normalize_level(level)
    if normalized and LEVELS[normalized] then
      return normalized
    end

    local numeric = tonumber(level)
    if numeric then
      for name, value in pairs(LEVELS) do
        if value == numeric then
          return name
        end
      end
    end

    return nil
  end

  if type(level) == "number" then
    local numeric = math.floor(level)
    for name, value in pairs(LEVELS) do
      if value == numeric then
        return name
      end
    end
  end

  return nil
end

local function default_settings_reader(key)
  if type(ModSettingGet) ~= "function" then
    return nil
  end

  local ok, value = pcall(ModSettingGet, key)
  if ok then
    return value
  end

  return nil
end

function Logger:new(config)
  if self ~= Logger then
    config = self
  end

  if config == nil or config == "" then
    config = {}
  end

  if type(config) == "string" then
    config = { tag = config }
  end

  local instance = setmetatable({
    _tag = config.tag or DEFAULTS.tag,
    _prefix = config.prefix or DEFAULTS.prefix,
    _levels = LEVELS,
    _level = DEFAULTS.level,
    _level_setting_key = config.level_setting_key or DEFAULTS.level_setting_key,
    _settings_reader = config.settings_reader or default_settings_reader,
  }, Logger)

  if config.level then
    instance:set_level(config.level)
  else
    instance:set_level_from_settings()
  end

  return instance
end

function Logger:set_level(level)
  local resolved = resolve_level_name(level)
  if resolved then
    self._level = resolved
    return true
  end

  print(string.format(
    "%s[WARN][Logger] Unknown log level '%s', keep %s",
    self._prefix,
    tostring(level),
    self._level
  ))

  return false
end

function Logger:_read_level_setting()
  if not self._settings_reader or not self._level_setting_key then
    return nil
  end

  local ok, value = pcall(self._settings_reader, self._level_setting_key)
  if ok then
    return value
  end

  print(string.format(
    "%s[WARN][Logger] Failed to read log level setting: %s",
    self._prefix,
    tostring(value)
  ))

  return nil
end

function Logger:set_level_from_settings()
  local level_from_settings = self:_read_level_setting()
  if level_from_settings ~= nil then
    self:set_level(level_from_settings)
  end
end

function Logger:set_prefix(prefix)
  if prefix and prefix ~= "" then
    self._prefix = prefix
  end
end

function Logger:set_tag(tag)
  if tag and tag ~= "" then
    self._tag = tag
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

  local output = string.format("[%s][%s][%s] %s", self._prefix, level, resolved_tag, resolved_message)

  if level == "ERROR" then
    error(output, 2)
  else
    print(output)
  end
end

function Logger:verbose(message, ...)
  self:_emit("VERBOSE", self._tag, message, ...)
end

function Logger:debug(message, ...)
  self:_emit("DEBUG", self._tag, message, ...)
end

function Logger:info(message, ...)
  self:_emit("INFO", self._tag, message, ...)
end

function Logger:warn(message, ...)
  self:_emit("WARN", self._tag, message, ...)
end

function Logger:error(message, ...)
  self:_emit("ERROR", self._tag, message, ...)
end

return Logger
