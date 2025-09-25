local json = {}

local escape_char_map = {
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t",
  ["\"] = "\\\\",
  ['"'] = '\\"',
}

local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04X", c:byte())
end

local function encode_string(str)
  return '"' .. str:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function is_array(tbl)
  local max_index = 0
  local count = 0
  for k, _ in pairs(tbl) do
    if type(k) == "number" and k > 0 and math.floor(k) == k then
      if k > max_index then
        max_index = k
      end
      count = count + 1
    else
      return false
    end
  end
  return max_index == count
end

local function encode_value(value)
  local t = type(value)

  if t == "nil" then
    return "null"
  elseif t == "boolean" then
    return value and "true" or "false"
  elseif t == "number" then
    return tostring(value)
  elseif t == "string" then
    return encode_string(value)
  elseif t == "table" then
    if next(value) == nil then
      return "{}"
    end

    if is_array(value) then
      local parts = {}
      for i = 1, #value do
        parts[i] = encode_value(value[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      local parts = {}
      local keys = {}
      for k in pairs(value) do
        keys[#keys + 1] = k
      end
      table.sort(keys)
      for i, k in ipairs(keys) do
        if type(k) ~= "string" then
          error("JSON object keys must be strings")
        end
        parts[i] = encode_string(k) .. ":" .. encode_value(value[k])
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  else
    error("Unsupported JSON type: " .. t)
  end
end

function json.encode(value)
  return encode_value(value)
end

local function skip_whitespace(str, index)
  local _, next_index = str:find("^%s*", index)
  return (next_index or index - 1) + 1
end

local function parse_string(str, index)
  local result = {}
  index = index + 1
  local len = #str
  while index <= len do
    local c = str:sub(index, index)
    if c == '"' then
      return table.concat(result), index + 1
    elseif c == '\\' then
      index = index + 1
      local esc = str:sub(index, index)
      if esc == '"' or esc == '\\' or esc == '/' then
        result[#result + 1] = esc
      elseif esc == 'b' then
        result[#result + 1] = "\b"
      elseif esc == 'f' then
        result[#result + 1] = "\f"
      elseif esc == 'n' then
        result[#result + 1] = "\n"
      elseif esc == 'r' then
        result[#result + 1] = "\r"
      elseif esc == 't' then
        result[#result + 1] = "\t"
      elseif esc == 'u' then
        local hex = str:sub(index + 1, index + 4)
        result[#result + 1] = string.char(tonumber(hex, 16))
        index = index + 4
      else
        error("Invalid escape sequence \\" .. esc .. "\"")
      end
    else
      result[#result + 1] = c
    end
    index = index + 1
  end
  error("Unterminated string")
end

local function parse_number(str, index)
  local num_str = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", index)
  if not num_str then
    error("Invalid number at position " .. index)
  end
  local number = tonumber(num_str)
  if not number then
    error("Invalid number format: " .. num_str)
  end
  return number, index + #num_str
end

local function parse_literal(str, index, literal, value)
  if str:sub(index, index + #literal - 1) == literal then
    return value, index + #literal
  end
  error("Invalid literal at position " .. index)
end

local function parse_array(str, index)
  local result = {}
  index = index + 1
  index = skip_whitespace(str, index)
  if str:sub(index, index) == ']' then
    return result, index + 1
  end

  while true do
    local value
    value, index = json._parse(str, index)
    result[#result + 1] = value
    index = skip_whitespace(str, index)
    local char = str:sub(index, index)
    if char == ']' then
      return result, index + 1
    elseif char ~= ',' then
      error("Expected ',' or ']' in array")
    end
    index = skip_whitespace(str, index + 1)
  end
end

local function parse_object(str, index)
  local result = {}
  index = index + 1
  index = skip_whitespace(str, index)
  if str:sub(index, index) == '}' then
    return result, index + 1
  end

  while true do
    local key
    key, index = parse_string(str, index)
    index = skip_whitespace(str, index)
    if str:sub(index, index) ~= ':' then
      error("Expected ':' after key in object")
    end
    index = skip_whitespace(str, index + 1)
    local value
    value, index = json._parse(str, index)
    result[key] = value
    index = skip_whitespace(str, index)
    local char = str:sub(index, index)
    if char == '}' then
      return result, index + 1
    elseif char ~= ',' then
      error("Expected ',' or '}' in object")
    end
    index = skip_whitespace(str, index + 1)
  end
end

function json._parse(str, index)
  index = skip_whitespace(str, index)
  local char = str:sub(index, index)

  if char == '"' then
    return parse_string(str, index)
  elseif char == '{' then
    return parse_object(str, index)
  elseif char == '[' then
    return parse_array(str, index)
  elseif char == '-' or char:match('%d') then
    return parse_number(str, index)
  elseif char == 'n' then
    return parse_literal(str, index, "null", nil)
  elseif char == 't' then
    return parse_literal(str, index, "true", true)
  elseif char == 'f' then
    return parse_literal(str, index, "false", false)
  end

  error("Unexpected character '" .. char .. "' at position " .. index)
end

function json.decode(str)
  if type(str) ~= "string" then
    error("Expected string for JSON decode")
  end
  local value, index = json._parse(str, 1)
  index = skip_whitespace(str, index)
  if index <= #str then
    error("Unexpected trailing characters in JSON")
  end
  return value
end

return json
