-- selene: allow(undefined_variable)
local extra_modifiers = extra_modifiers

local _critical_plus_small = extra_modifiers.critical_plus_small
extra_modifiers.critical_plus_small = function()
  -- selene: allow(undefined_variable)
  local c1 = c
  local damage_critical_chance = c1.damage_critical_chance

  _critical_plus_small()

  -- selene: allow(undefined_variable)
  local c2 = c
  if c2.damage_critical_chance > damage_critical_chance then
    c2.damage_critical_chance = damage_critical_chance + (c2.damage_critical_chance - damage_critical_chance) * 0.25
  end
end

local _powerful_shot = extra_modifiers.powerful_shot
extra_modifiers.powerful_shot = function()
  -- selene: allow(undefined_variable)
  local c1 = c
  local damage_explosion_add = c1.damage_explosion_add
  local damage_projectile_add = c1.damage_projectile_add

  _powerful_shot()

  -- selene: allow(undefined_variable)
  local c2 = c
  if c2.damage_explosion_add > damage_explosion_add then
    c2.damage_explosion_add = damage_explosion_add + (c2.damage_explosion_add - damage_explosion_add) * 0.1
  end
  if c2.damage_projectile_add > damage_projectile_add then
    c2.damage_projectile_add = damage_projectile_add + (c2.damage_projectile_add - damage_projectile_add) * 0.1
  end
end

extra_modifiers.food_clock = function()
  -- selene: allow(undefined_variable)
  local c = c
  c.extra_entities = c.extra_entities .. "mods/kaleva_koetus/files/entities/misc/food_clock_b9.xml,"
end

local _lower_spread = extra_modifiers.lower_spread
extra_modifiers.lower_spread = function()
  -- selene: allow(undefined_variable)
  local c1 = c
  local damage_explosion_add = c1.damage_explosion_add
  local damage_projectile_add = c1.damage_projectile_add

  _lower_spread()

  -- selene: allow(undefined_variable)
  local c2 = c
  if c2.damage_explosion_add > damage_explosion_add then
    c2.damage_explosion_add = damage_explosion_add + (c2.damage_explosion_add - damage_explosion_add) * 0.1
  end
  if c2.damage_projectile_add > damage_projectile_add then
    c2.damage_projectile_add = damage_projectile_add + (c2.damage_projectile_add - damage_projectile_add) * 0.1
  end
end
