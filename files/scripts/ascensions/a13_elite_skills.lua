local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("a13_elite_skills.lua")

local _ = dofile_once("data/scripts/gun/procedural/gun_procedural.lua")

local a13_elite_skills = {}

local ELITE_HP_MULTIPLIER = 2
local ELITE_FIRE_LATE = 2

function a13_elite_skills:add_homing(enemy_entity_id)
  log:debug("add_homing")
  local existing_component = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "HomingComponent")
  if existing_component then
    return
  end

  local _ = EntityAddComponent2(enemy_entity_id, "HomingComponent", {
    target_tag = "prey",
    homing_targeting_coeff = 13,
    detect_distance = 300,
    homing_velocity_multiplier = 1.0,
  })
end

function a13_elite_skills:increase_hp(enemy_entity_id)
  log:debug("increase_hp")
  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "DamageModelComponent")
  if not component_id then
    return
  end

  local current_hp = ComponentGetValue2(component_id, "hp")
  if not current_hp then
    return
  end

  ComponentSetValue2(component_id, "hp", current_hp * a13_elite_skills.hp_multiplier)
end

function a13_elite_skills:increase_fire_rate(enemy_entity_id)
  log:debug("increase_fire_rate")

  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "AnimalAIComponent")
  if not component_id then
    return
  end

  local frames_between = ComponentGetValue2(component_id, "attack_ranged_frames_between")
  if not frames_between then
    return
  end

  local updated_frames_between = math.max(1, math.floor(frames_between * ELITE_FIRE_LATE))
  ComponentSetValue2(component_id, "attack_ranged_frames_between", updated_frames_between)
end

function a13_elite_skills:add_extra_projectile(enemy_entity_id)
  log:debug("add_extra_projectile")

  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "AnimalAIComponent")
  if not component_id then
    return
  end

  local projectile_min = ComponentGetValue2(component_id, "attack_ranged_entity_count_min")
  local projectile_max = ComponentGetValue2(component_id, "attack_ranged_entity_count_max")

  if not projectile_min or not projectile_max then
    return
  end

  local multiplier = a13_elite_skills.projectile_multiplier
  ComponentSetValue2(component_id, "attack_ranged_entity_count_min", projectile_min * multiplier)
  ComponentSetValue2(component_id, "attack_ranged_entity_count_max", projectile_max * multiplier)
end

function a13_elite_skills:increase_damage(enemy_entity_id)
  log:debug("increase_damage")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_damage_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:increase_explosion(enemy_entity_id)
  log:debug("increase_explosion")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_explosion_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:increase_speed(enemy_entity_id)
  log:debug("increase_speed")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_speed_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:use_wand(enemy_entity_id)
  -- NOTE:
  -- I saw the free wand that wasn't held by an enemy.
  -- I could probably delete free wands, generate InventoryQuick in the Enemy Entity, and inject wand data directly.
  -- But I like the whimsical nature of Noita's scripts, so I won't rewrite this.
  -- This method refers to noita's nightmare mode
  log:debug("use_wand")

  local component_id = EntityGetFirstComponent(enemy_entity_id, "ItemPickUpperComponent")
  if not component_id then
    return
  end

  local x, y = EntityGetTransform(enemy_entity_id)
  SetRandomSeed(x + enemy_entity_id, y)
  local wand_level = math.floor(y / (512 * 4))
  if wand_level < 2 then
    wand_level = 2
  end
  if 5 < wand_level and wand_level < 8 then
    wand_level = 5
  end
  if wand_level > 6 then
    wand_level = 10
  end

  local wand_level_str = "0" .. tostring(wand_level)
  if wand_level >= 10 then
    wand_level_str = "10"
  end
  local wand_file = "data/entities/items/"
  if Random(1, 100) < 50 then
    wand_file = wand_file .. "wand_level_" .. wand_level_str .. ".xml"
  else
    wand_file = wand_file .. "wand_unshuffle_" .. wand_level_str .. ".xml"
  end
  local _ = EntityLoad(wand_file, x, y)
end

a13_elite_skills.skills = {
  a13_elite_skills.add_homing,
  a13_elite_skills.increase_hp,
  a13_elite_skills.increase_fire_rate,
  a13_elite_skills.increase_damage,
  a13_elite_skills.increase_explosion,
  a13_elite_skills.add_extra_projectile,
  a13_elite_skills.use_wand,
}

return a13_elite_skills
