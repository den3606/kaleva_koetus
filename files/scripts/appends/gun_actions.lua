local RandomUtils = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a15_random_utils.lua")

local function a15_action(action)
  if action.name ~= nil and string.sub(action.name, 1, 1) == "$" then
    action.name = "$kaleva_koetus_a15_" .. string.sub(action.name, 2)
  else
    action.name = "$kaleva_koetus_a15_" .. action.id
  end

  local rnd = math.random()

  -- 使用回数かマナにデバフをかける
  if rnd < 0.5 and not action.max_uses then
    action.max_uses = action.price * 10
  else
    if action.mana then
      action.mana = action.mana * math.random(1.2, 1.7)
    end
  end

  local has_cool_time = 0.5 < math.random() or true
  local has_fire_rate_debuff = 0.5 < math.random() or false
  local selected_debuff = RandomUtils.random_unique_integers(1, 5, 2)
  local debuff_fire_rate_wait = math.random(5, 15)
  local debuff_reload_time = math.random(5, 15)
  local debuff_spread_degrees = math.random(3, 7)
  local debuff_damage_critical_chance = math.random(-7, -1)
  local debuff_speed_multiplier = math.random(5, 15) * 0.1

  local _func_action = action.action
  action.action = function(recursion_level, iteration)
    -- selene: allow(undefined_variable)
    local c = c

    if has_cool_time then
      if has_fire_rate_debuff then
        c.fire_rate_wait = c.fire_rate_wait + debuff_fire_rate_wait
      else
        -- selene: allow(unscoped_variables,unused_variable)
        current_reload_time = current_reload_time + debuff_reload_time
      end
    end

    -- selene: allow(undefined_variable)
    local debuff_effects = {
      function()
        c.spread_degrees = c.spread_degrees + debuff_spread_degrees
      end,
      function()
        c.damage_critical_chance = c.damage_critical_chance + debuff_damage_critical_chance
      end,
      function()
        c.child_speed_multiplier = c.child_speed_multiplier * debuff_speed_multiplier
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

    for _, index in ipairs(selected_debuff) do
      debuff_effects[index]()
    end

    _func_action(recursion_level, iteration)
  end
end

local actions_seed = RandomUtils.derive_seed("gun_actions")
math.randomseed(actions_seed)

-- selene: allow(undefined_variable)
local actions = actions
local target_indexes = RandomUtils.random_unique_integers(1, #actions, math.floor(#actions * RandomUtils.UNCOMPLETED_MULTIPLIER))
for _, index in ipairs(target_indexes) do
  if actions[index].id ~= "MANA_REDUCE" then
    local action_seed = RandomUtils.derive_seed("gun_action_" .. tostring(index))
    math.randomseed(action_seed)
    a15_action(actions[index])
  end
end
