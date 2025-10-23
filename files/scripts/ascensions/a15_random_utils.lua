-- selene: allow(undefined_variable)
local bit = bit

local RandomUtils = {}
RandomUtils.UNCOMPLETED_MULTIPLIER = 0.3

local MAGIC_MULTIPLIER = 0x45d9f3b
local MASK_32BIT = 0xFFFFFFFF

local function addr_seed_from_table(t)
  local s = tostring(t or {})
  local hex = s:match("0x(%x+)") or s:match("(%x+)$") or "0"
  local n = tonumber(hex, 16) or 0
  n = bit.bxor(n, bit.rshift(n, 16))
  n = bit.band(n * MAGIC_MULTIPLIER, MASK_32BIT)
  return n
end

local function mix_integer(n, mix_val)
  n = bit.bxor(n, mix_val)
  n = bit.band(n * MAGIC_MULTIPLIER, MASK_32BIT)
  n = bit.bxor(n, bit.rshift(n, 16))
  return n
end

local gun_action_seed_key = "kaleva_koetus.gun_action_seed"

function RandomUtils.init_root_seed()
  if SessionNumbersGetValue("is_biome_map_initialized") == "0" then
    local gun_action_seed = addr_seed_from_table()
    local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()
    gun_action_seed = mix_integer(gun_action_seed, year)
    gun_action_seed = mix_integer(gun_action_seed, month)
    gun_action_seed = mix_integer(gun_action_seed, day)
    gun_action_seed = mix_integer(gun_action_seed, hour)
    gun_action_seed = mix_integer(gun_action_seed, minute)
    gun_action_seed = mix_integer(gun_action_seed, second)
    ModSettingSet(gun_action_seed_key, gun_action_seed)
  end
end

function RandomUtils.derive_seed(domain)
  local derived_seed = ModSettingGet(gun_action_seed_key) or 0
  for i = 1, #domain do
    local char_code = string.byte(domain, i)
    derived_seed = mix_integer(derived_seed, char_code)
  end
  return derived_seed
end

function RandomUtils.random_unique_integers(min, max, count)
  min = min - 1
  local total = max - min
  local numbers = {}
  for i = 1, total do
    numbers[i] = i + min
  end

  for i = 1, count do
    local j = math.random(i, total)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    result[i] = numbers[i]
  end

  return result
end

return RandomUtils
