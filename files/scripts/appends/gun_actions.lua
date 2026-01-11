local RNG = dofile_once("mods/kaleva_koetus/files/scripts/random_genarator.lua")

local UNCOMPLETED_MULTIPLIER = 0.5

local function debuff_template_fire_rate_wait()
  local debuff_fire_rate_wait = math.random(5, 15)
  return function(c)
    c.fire_rate_wait = c.fire_rate_wait + debuff_fire_rate_wait
  end
end

local function debuff_template_reload_time()
  local debuff_reload_time = math.random(5, 15)
  return function()
    -- selene: allow(unscoped_variables,unused_variable)
    current_reload_time = current_reload_time + debuff_reload_time
  end
end

local debuff_templates = {
  function()
    local debuff_spread_degrees = math.random(3, 7)
    return function(c)
      c.spread_degrees = c.spread_degrees + debuff_spread_degrees
    end
  end,
  function()
    local debuff_damage_critical_chance = math.random(-7, -1)
    return function(c)
      c.damage_critical_chance = c.damage_critical_chance + debuff_damage_critical_chance
    end
  end,
  function()
    local debuff_speed_multiplier = math.random(5, 15) * 0.1
    return function(c)
      c.speed_multiplier = c.speed_multiplier * debuff_speed_multiplier
      c.child_speed_multiplier = c.child_speed_multiplier * debuff_speed_multiplier
    end
  end,
  function()
    local debuff_damage_projectile_add = math.random(-5, -1) * 0.04
    return function(c)
      c.damage_projectile_add = c.damage_projectile_add + debuff_damage_projectile_add
    end
  end,
  function()
    local debuff_explosion_radius = math.random(-10, -3)
    local debuff_damage_explosion_add = math.random(-20, -5) * 0.04
    return function(c)
      c.explosion_radius = c.explosion_radius + debuff_explosion_radius
      c.damage_explosion_add = c.damage_explosion_add + debuff_damage_explosion_add
    end
  end,
}

local function a15_action(action)
  action.name = "$kaleva_koetus_a15_action_" .. action.id
  action.sprite = "mods/kaleva_koetus/a15/sprites/" .. action.sprite
  if action.custom_xml_file ~= nil then
    action.custom_xml_file = "mods/kaleva_koetus/a15/custom_cards/" .. action.custom_xml_file
  end

  if action.max_uses == nil then
    action.max_uses = action.price * 2
  end

  if action.mana and action.mana > 0 then
    if math.random() < 0.5 then
      action.mana = math.floor(action.mana * RNG.random_float(1.2, 1.7))
    end
  end

  local debuff_effects = {}

  if math.random() < 0.5 then
    table.insert(debuff_effects, debuff_template_fire_rate_wait())
  else
    table.insert(debuff_effects, debuff_template_reload_time())
  end

  local selected_debuff = RNG.random_unique_integers(1, #debuff_templates, 2)
  for _, index in ipairs(selected_debuff) do
    table.insert(debuff_effects, debuff_templates[index]())
  end

  local _func_action = action.action
  action.action = function(recursion_level, iteration)
    -- selene: allow(undefined_variable)
    local c = c

    for _, debuff_effect in ipairs(debuff_effects) do
      debuff_effect(c)
    end

    _func_action(recursion_level, iteration)
  end
end

local root_seed = RNG.get_root_seed()
if root_seed == nil then
  return
end

local actions_seed = RNG.derive_seed(root_seed, "gun_actions")
math.randomseed(actions_seed)

-- selene: allow(undefined_variable)
local actions = actions
local target_indexes = RNG.random_unique_integers(1, #actions, math.floor(#actions * UNCOMPLETED_MULTIPLIER))
for _, index in ipairs(target_indexes) do
  local action_seed = RNG.derive_seed(root_seed, "gun_action_" .. tostring(index))
  math.randomseed(action_seed)
  a15_action(actions[index])
end
