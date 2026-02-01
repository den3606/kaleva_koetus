-- selene: allow(undefined_variable)
local bit = bit

local MAGIC_MULTIPLIER = 0x45d9f3b
local MASK_32BIT = 0xFFFFFFFF

local function mix_integer(n, mix_val)
  n = bit.bxor(n, mix_val)
  n = bit.band(n * MAGIC_MULTIPLIER, MASK_32BIT)
  n = bit.bxor(n, bit.rshift(n, 16))
  return n
end

local RNG = {}

local root_seed_file = "mods/kaleva_koetus/root_seed.txt"

-- Called after OnMagicNumbersAndWorldSeedInitialized
function RNG.init_root_seed()
  ModTextFileSetContent(root_seed_file, StatsGetValue("world_seed") or "0")
end

function RNG.get_root_seed()
  if ModDoesFileExist(root_seed_file) == false then
    return nil
  end
  return tonumber(ModTextFileGetContent(root_seed_file))
end

function RNG.derive_seed(parent_seed, domain)
  local derived_seed = parent_seed
  for i = 1, #domain do
    local char_code = string.byte(domain, i)
    derived_seed = mix_integer(derived_seed, char_code)
  end
  return derived_seed
end

function RNG.random_unique_integers(min, max, count)
  min = min - 1
  local total = max - min
  local numbers = {}
  for i = 1, total do
    numbers[i] = i + min
  end

  for i = 1, math.min(count, total) do
    local j = math.random(i, total)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    result[i] = numbers[i]
  end

  return result
end

function RNG.random_float(min, max)
  return min + math.random() * (max - min)
end

return RNG
