---@class path32
local path32 = {}

local band = bit.band
local floor = math.floor

local function extract5(v, from)
  return band(floor(v / (2 ^ from)), 0x1F)
end

local function extract8(v, from)
  return band(floor(v / (2 ^ from)), 0xFF)
end

---@class Path32Encoder
---@field [number] number
---@field pad string

---@param spad string?
---@return Path32Encoder
function path32.makeencoder(spad)
  local encoder = {}
  local alphabet = "abcdefghijklmnopqrstuvwxyz234567"

  for i = 0, 31 do
    local c = alphabet:sub(i + 1, i + 1)
    encoder[i] = c:byte()
  end

  encoder.pad = spad or "_"

  return encoder
end

---@class Path32Decoder
---@field [number] number
---@field pad string

---@param spad string?
---@return Path32Decoder
function path32.makedecoder(spad)
  local decoder = {}
  local enc = path32.makeencoder(spad)
  for i = 0, 31 do
    decoder[enc[i]] = i
  end
  decoder.pad = enc.pad
  return decoder
end

local DEFAULT_ENCODER = path32.makeencoder()
local DEFAULT_DECODER = path32.makedecoder()

local char, concat = string.char, table.concat

---@param str string
---@param encoder Path32Encoder?
---@return string
function path32.encode(str, encoder)
  encoder = encoder or DEFAULT_ENCODER
  local pad_c = encoder.pad

  local t, k, n = {}, 1, #str
  local remainder = n % 5

  for i = 1, n - remainder, 5 do
    local b1, b2, b3, b4, b5 = str:byte(i, i + 4)
    local v                  = b1 * 0x100000000 + b2 * 0x1000000 + b3 * 0x10000 + b4 * 0x100 + b5

    t[k]                     = char(encoder[extract5(v, 35)])
    t[k + 1]                 = char(encoder[extract5(v, 30)])
    t[k + 2]                 = char(encoder[extract5(v, 25)])
    t[k + 3]                 = char(encoder[extract5(v, 20)])
    t[k + 4]                 = char(encoder[extract5(v, 15)])
    t[k + 5]                 = char(encoder[extract5(v, 10)])
    t[k + 6]                 = char(encoder[extract5(v, 5)])
    t[k + 7]                 = char(encoder[extract5(v, 0)])
    k                        = k + 8
  end

  if remainder > 0 then
    local v = 0
    if remainder == 1 then
      local b1 = str:byte(n)
      v        = b1 * 0x4

      t[k]     = char(encoder[extract5(v, 5)])
      t[k + 1] = char(encoder[extract5(v, 0)])
      t[k + 2] = pad_c; t[k + 3] = pad_c; t[k + 4] = pad_c
      t[k + 5] = pad_c; t[k + 6] = pad_c; t[k + 7] = pad_c
    elseif remainder == 2 then
      local b1, b2 = str:byte(n - 1, n)
      v            = b1 * 0x1000 + b2 * 0x10

      t[k]         = char(encoder[extract5(v, 15)])
      t[k + 1]     = char(encoder[extract5(v, 10)])
      t[k + 2]     = char(encoder[extract5(v, 5)])
      t[k + 3]     = char(encoder[extract5(v, 0)])
      t[k + 4]     = pad_c; t[k + 5] = pad_c; t[k + 6] = pad_c; t[k + 7] = pad_c
    elseif remainder == 3 then
      local b1, b2, b3 = str:byte(n - 2, n)
      v                = b1 * 0x20000 + b2 * 0x200 + b3 * 0x2

      t[k]             = char(encoder[extract5(v, 20)])
      t[k + 1]         = char(encoder[extract5(v, 15)])
      t[k + 2]         = char(encoder[extract5(v, 10)])
      t[k + 3]         = char(encoder[extract5(v, 5)])
      t[k + 4]         = char(encoder[extract5(v, 0)])
      t[k + 5]         = pad_c; t[k + 6] = pad_c; t[k + 7] = pad_c
    elseif remainder == 4 then
      local b1, b2, b3, b4 = str:byte(n - 3, n)
      v                    = b1 * 0x8000000 + b2 * 0x80000 + b3 * 0x800 + b4 * 0x8

      t[k]                 = char(encoder[extract5(v, 30)])
      t[k + 1]             = char(encoder[extract5(v, 25)])
      t[k + 2]             = char(encoder[extract5(v, 20)])
      t[k + 3]             = char(encoder[extract5(v, 15)])
      t[k + 4]             = char(encoder[extract5(v, 10)])
      t[k + 5]             = char(encoder[extract5(v, 5)])
      t[k + 6]             = char(encoder[extract5(v, 0)])
      t[k + 7]             = pad_c
    end
  end

  return concat(t)
end

---@param p32 string
---@param decoder Path32Decoder?
---@return string?
function path32.decode(p32, decoder)
  decoder = decoder or DEFAULT_DECODER
  local pad_v = (decoder.pad or "_"):byte()

  local n = #p32
  if n == 0 then
    return ""
  end
  if n % 8 ~= 0 then
    return nil
  end

  local padding = 7
  for i = 0, 6 do
    if p32:byte(n - i) ~= pad_v then
      padding = i
      break
    end
  end

  if not (padding == 0 or padding == 1 or padding == 3 or padding == 4 or padding == 6) then
    return nil
  end

  local t, k = {}, 1

  for i = 1, n - 8, 8 do
    local c1, c2, c3, c4, c5, c6, c7, c8 = p32:byte(i, i + 7)

    local v1 = decoder[c1]
    local v2 = decoder[c2]
    local v3 = decoder[c3]
    local v4 = decoder[c4]
    local v5 = decoder[c5]
    local v6 = decoder[c6]
    local v7 = decoder[c7]
    local v8 = decoder[c8]

    if not (v1 and v2 and v3 and v4 and v5 and v6 and v7 and v8) then
      return nil
    end

    local v = v1 * 0x800000000 +
        v2 * 0x40000000 +
        v3 * 0x2000000 +
        v4 * 0x100000 +
        v5 * 0x8000 +
        v6 * 0x400 +
        v7 * 0x20 +
        v8

    t[k] = char(extract8(v, 32), extract8(v, 24), extract8(v, 16), extract8(v, 8), extract8(v, 0))

    k = k + 1
  end

  local c1, c2, c3, c4, c5, c6, c7, c8 = p32:byte(n - 7, n)

  local v1 = decoder[c1]
  local v2 = decoder[c2]
  local v3 = padding >= 6 and 0 or decoder[c3]
  local v4 = padding >= 5 and 0 or decoder[c4]
  local v5 = padding >= 4 and 0 or decoder[c5]
  local v6 = padding >= 3 and 0 or decoder[c6]
  local v7 = padding >= 2 and 0 or decoder[c7]
  local v8 = padding >= 1 and 0 or decoder[c8]

  if not (v1 and v2 and v3 and v4 and v5 and v6 and v7 and v8) then
    return nil
  end

  local v = v1 * 0x800000000 +
      v2 * 0x40000000 +
      v3 * 0x2000000 +
      v4 * 0x100000 +
      v5 * 0x8000 +
      v6 * 0x400 +
      v7 * 0x20 +
      v8

  if padding == 6 then
    t[k] = char(extract8(v, 32))
  elseif padding == 4 then
    t[k] = char(extract8(v, 32), extract8(v, 24))
  elseif padding == 3 then
    t[k] = char(extract8(v, 32), extract8(v, 24), extract8(v, 16))
  elseif padding == 1 then
    t[k] = char(extract8(v, 32), extract8(v, 24), extract8(v, 16), extract8(v, 8))
  else
    t[k] = char(extract8(v, 32), extract8(v, 24), extract8(v, 16), extract8(v, 8), extract8(v, 0))
  end

  return concat(t)
end

return path32
