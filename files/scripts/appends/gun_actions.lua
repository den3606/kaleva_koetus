local function addr_seed_from_table(t)
  local s = tostring(t or {})
  local hex = s:match("0x(%x+)") or s:match("(%x+)$") or "0"
  local n = tonumber(hex, 16) or 0

  -- 32bitに畳んで拡散（軽いミックス）
  -- n >> 16 を算術演算で実装
  local shift = math.floor(n / 65536)

  -- n ^ (n >> 16) のXORを算術演算で実装
  local xor_result = 0
  local a, b = n, shift
  for i = 0, 31 do
    local bit_val = 2 ^ i
    local bit_a = math.floor(a / bit_val) % 2
    local bit_b = math.floor(b / bit_val) % 2
    if bit_a ~= bit_b then
      xor_result = xor_result + bit_val
    end
  end

  -- 乗算して32bitマスク
  n = (xor_result * 0x45d9f3b) % 4294967296

  return n
end

local function random_unique_integers(min, max, count)
  local numbers = {}
  for i = min, max do
    table.insert(numbers, i)
  end

  -- Fisher-Yates shuffle
  for i = #numbers, 2, -1 do
    local j = math.random(1, i)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    table.insert(result, numbers[i])
  end

  return result
end
local function a15_action(action)
  local _, _, _, _, minute, second = GameGetDateAndTimeUTC()
  math.randomseed(addr_seed_from_table() + minute + second)

  action.name = GameTextGetTranslatedOrNot("$kaleva_koetus_broken_spell") .. GameTextGetTranslatedOrNot(action.name)

  local rnd = math.random()

  -- 使用回数かマナにデバフをかける
  if rnd < 0.5 and not action.max_uses then
    action.max_uses = action.price * 10
  else
    if action.mana then
      action.mana = action.mana * math.random(1.2, 2.0)
    end
  end

  local _func_action = action.action
  action.action = function(recursion_level, iteration)
    -- selene: allow(undefined_variable)
    local c = c

    if 0.5 < math.random() then
      if 0.5 < math.random() then
        -- selene: allow(unscoped_variables,unused_variable)
        current_reload_time = current_reload_time + math.random(10, 60)
      else
        c.fire_rate_wait = c.fire_rate_wait + math.random(10, 60)
      end
    end

    local selected = random_unique_integers(1, 5, 2)
    -- selene: allow(undefined_variable)
    local debuff_effects = {
      function()
        c.spread_degrees = c.spread_degrees + math.random(5, 10)
      end,
      function()
        c.damage_critical_chance = c.damage_critical_chance + math.random(-10, -1)
      end,
      function()
        c.child_speed_multiplier = math.random(5, 15) * 0.1
      end,
      function()
        c.damage_projectile_add = c.damage_projectile_add * 0.5
      end,
      function()
        if c.damage_explosion then
          c.damage_explosion = c.damage_explosion * 0.5
        end
      end,
    }

    for _, index in ipairs(selected) do
      debuff_effects[index]()
    end

    _func_action(recursion_level, iteration)
  end
end

-- selene: allow(undefined_variable)
for _, action in ipairs(actions) do
  -- NOTE:
  -- ダミーの画像参照をから、対象スペルかを判断している
  local exist = ModImageDoesExist("kk/a15/" .. action.sprite)
  if exist then
    a15_action(action)
  end
end
