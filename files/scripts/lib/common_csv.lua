---@class common_csv
local common_csv = {}

---@class parsed_csv
---@field _csv string
---@field _data table
---@field _lines table
local parsed_csv = {}
parsed_csv.__index = parsed_csv
parsed_csv.__tostring = function(self)
  return self._csv
end

---@param csv_string string
---@param start_pos number
---@param finish_pos number
---@return string|nil
---@return number|nil
local function _next(csv_string, start_pos, finish_pos)
  if start_pos > finish_pos then
    return nil
  end

  local in_quotes = false
  local i = start_pos

  while i <= finish_pos do
    local byte = csv_string:byte(i)

    if byte == 34 --[[ '"' ]] then
      if i < finish_pos and csv_string:byte(i + 1) == 34 then
        i = i + 1
      else
        if in_quotes == true then
          return csv_string:sub(start_pos, i - 1), i + 2
        else
          in_quotes = true
          start_pos = i + 1
        end
      end
    elseif in_quotes == false and byte == 44 --[[ ',' ]] then
      return csv_string:sub(start_pos, i - 1), i + 1
    end
    i = i + 1
  end

  return nil
end

---@param csv_string string
---@return parsed_csv
function common_csv.parse(csv_string)
  local parser = setmetatable({}, parsed_csv)
  parser._csv = csv_string
  parser._data = {}
  parser._lines = {}

  local len = #csv_string
  if len == 0 then
    return parser
  end

  local pos = 1
  while pos <= len do
    local line_end_pos
    local next_line_start = csv_string:find('\n', pos)
    if next_line_start ~= nil then
      if csv_string:byte(next_line_start - 1) == 13 --[[ '\r' ]] then
        line_end_pos = next_line_start - 2
      else
        line_end_pos = next_line_start - 1
      end
    else
      line_end_pos = len
      next_line_start = len
    end

    if pos > line_end_pos then
      break
    end

    local key, value_start = _next(csv_string, pos, line_end_pos)
    if key ~= nil and key ~= '' then
      parser._data[key] = { value_start, line_end_pos }
    end

    table.insert(parser._lines, { pos, line_end_pos })

    pos = next_line_start + 1
  end

  return parser
end

---@param key string
---@return string[]|nil
function parsed_csv:query(key)
  local csv_string = self._csv
  local indices = self._data[key]

  if indices == nil then
    return nil
  end

  local current_pos, finish_pos = indices[1], indices[2]
  local results = {}

  local field
  while current_pos <= finish_pos do
    field, current_pos = _next(csv_string, current_pos, finish_pos)

    if field == nil then
      break
    end

    table.insert(results, field)
  end

  return results
end

---@param index number
---@return string[]|nil
function parsed_csv:line(index)
  local csv_string = self._csv
  local indices = self._lines[index]

  if indices == nil then
    return nil
  end

  local current_pos, finish_pos = indices[1], indices[2]
  local results = {}

  local field
  while current_pos <= finish_pos do
    field, current_pos = _next(csv_string, current_pos, finish_pos)

    if field == nil then
      break
    end

    table.insert(results, field)
  end

  return results
end

---@param data_table table
---@param min_columns number|nil
function parsed_csv:append(data_table, min_columns)
  local new_csv_part = common_csv.build_csv(data_table, min_columns)

  if new_csv_part == '' then
    return
  end

  local old_csv = self._csv
  local end_pos = 0

  if #self._lines > 0 then
    end_pos = self._lines[#self._lines][2]
  end

  local splice_pos = old_csv:find('\n', end_pos, true)
  if splice_pos == nil then
    splice_pos = end_pos
  end

  local offset
  local new_csv_full
  if splice_pos == nil then
    offset = end_pos + 1
    local old_csv_part = old_csv:sub(1, end_pos)
    new_csv_full = old_csv_part .. '\n' .. new_csv_part
  else
    offset = splice_pos
    local old_csv_part = old_csv:sub(1, splice_pos)
    new_csv_full = old_csv_part .. new_csv_part
  end

  local temp_parser = common_csv.parse(new_csv_part)

  for _, line_indices in ipairs(temp_parser._lines) do
    line_indices[1] = line_indices[1] + offset
    line_indices[2] = line_indices[2] + offset
    table.insert(self._lines, line_indices)
  end

  for key, value_indices in pairs(temp_parser._data) do
    value_indices[1] = value_indices[1] + offset
    value_indices[2] = value_indices[2] + offset
    self._data[key] = value_indices
  end

  self._csv = new_csv_full
end

---@param field string
---@return string|nil
local function _process_field(field)
  local pos = 1
  while true do
    local start_seq = field:find('"', pos, true)
    if start_seq == nil then
      break
    end

    local end_seq_pos = field:find('[^"]', start_seq + 1, true)

    if end_seq_pos == nil then
      if (#field - start_seq + 1) % 2 ~= 0 then
        return nil
      end
      break
    end

    local count = end_seq_pos - start_seq
    if count % 2 ~= 0 then
      return nil
    end

    pos = end_seq_pos + 1
  end

  if field:find(',') then
    return '"' .. field .. '"'
  end

  return field
end

---@param key string
---@param value string[]
---@param min_columns number|nil
---@return string|nil
function common_csv.build_line_kv(key, value, min_columns)
  min_columns = min_columns or 0

  local fields = {}

  local processed_field = _process_field(key)
  if processed_field == nil then
    return nil
  end
  table.insert(fields, processed_field)

  local column_count = 1
  for _, field in ipairs(value) do
    processed_field = _process_field(field)
    if processed_field == nil then
      return nil
    end
    table.insert(fields, processed_field)
    column_count = column_count + 1
  end

  if column_count < min_columns then
    table.insert(fields, string.rep(',', min_columns - column_count - 1))
  end

  table.insert(fields, "")

  return table.concat(fields, ",")
end

---@param value string[]
---@param min_columns number|nil
---@return string|nil
function common_csv.build_line_array(value, min_columns)
  min_columns = min_columns or 0

  local fields = {}

  local column_count = 0
  for _, field in ipairs(value) do
    local processed_field = _process_field(field)
    if processed_field == nil then
      return nil
    end
    table.insert(fields, processed_field)
    column_count = column_count + 1
  end

  if column_count < min_columns then
    table.insert(fields, string.rep(',', min_columns - column_count - 1))
  end

  table.insert(fields, "")

  return table.concat(fields, ",")
end

---@param data_table table
---@param min_columns number|nil
---@return string
function common_csv.build_csv(data_table, min_columns)
  local lines = {}

  local array_keys = {}
  for index, value in ipairs(data_table) do
    array_keys[index] = true
    local line = common_csv.build_line_array(value, min_columns)
    if line ~= nil then
      table.insert(lines, line)
    end
  end
  for key, value in pairs(data_table) do
    if array_keys[key] ~= true then
      local line = common_csv.build_line_kv(key, value, min_columns)
      if line ~= nil then
        table.insert(lines, line)
      end
    end
  end
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

return common_csv
