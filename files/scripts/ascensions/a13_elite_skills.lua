-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
-- local log = Logger:new("a13_elite_skills.lua")

local _ = dofile_once("data/scripts/gun/procedural/gun_procedural.lua")

local a13_elite_skills = {}

local PROJECTILE_MULTIPLIER = 2
local ELITE_HP_MULTIPLIER = 2
local ELITE_FIRE_LATE = 2
local DAMAGE_MELEE_MULTIPLIER = 2

function a13_elite_skills:add_homing(enemy_entity_id)
  -- log:debug("add_homing")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_add_homing_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:add_extra_projectile(enemy_entity_id)
  -- log:debug("add_extra_projectile")

  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "AnimalAIComponent")
  if not component_id then
    return
  end

  local projectile_min = ComponentGetValue2(component_id, "attack_ranged_entity_count_min")
  local projectile_max = ComponentGetValue2(component_id, "attack_ranged_entity_count_max")

  ComponentSetValue2(component_id, "attack_ranged_entity_count_min", projectile_min * PROJECTILE_MULTIPLIER)
  ComponentSetValue2(component_id, "attack_ranged_entity_count_max", projectile_max * PROJECTILE_MULTIPLIER)
end

function a13_elite_skills:increase_projectile_fire_rate(enemy_entity_id)
  -- log:debug("increase_projectile_fire_rate")

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

function a13_elite_skills:increase_projectile_damage(enemy_entity_id)
  -- log:debug("increase_projectile_damage")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_damage_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:increase_projectile_explosion(enemy_entity_id)
  -- log:debug("increase_projectile_explosion")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_explosion_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:increase_projectile_speed(enemy_entity_id)
  -- log:debug("increase_projectile_speed")

  local _ = EntityAddComponent2(enemy_entity_id, "LuaComponent", {
    script_shot = "mods/kaleva_koetus/files/scripts/ascensions/a13_increase_speed_on_shot_append.lua",
    execute_every_n_frame = -1,
  })
end

function a13_elite_skills:increase_hp(enemy_entity_id)
  -- log:debug("increase_hp")
  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "DamageModelComponent")
  if not component_id then
    return
  end

  local max_hp = ComponentGetValue2(component_id, "max_hp")
  local current_hp = ComponentGetValue2(component_id, "hp")

  ComponentSetValue2(component_id, "max_hp", max_hp * ELITE_HP_MULTIPLIER)
  ComponentSetValue2(component_id, "hp", current_hp * ELITE_HP_MULTIPLIER)
end

function a13_elite_skills:increase_character_speed(enemy_entity_id)
  -- log:debug("increase_character_speed")
  local game_effect_comp, game_effect_entity = GetGameEffectLoadTo(enemy_entity_id, "MOVEMENT_FASTER_2X", false)
  if (game_effect_comp ~= nil) and (game_effect_entity ~= nil) then
    ComponentSetValue(game_effect_comp, "frames", "-1")
    local _ = EntityAddComponent2(game_effect_entity, "LuaComponent", {
      script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a13_cleanup_orphan_entity.lua",
      remove_after_executed = true,
    })
  end
end

function a13_elite_skills:increase_melee_damage(enemy_entity_id)
  -- log:debug("increase_melee_damage")
  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "AnimalAIComponent")
  if not component_id then
    return
  end
  local melee_enabled = ComponentGetValue2(component_id, "attack_melee_enabled")
  if melee_enabled == true then
    local melee_damage_min = ComponentGetValue2(component_id, "attack_melee_damage_min")
    local melee_damage_max = ComponentGetValue2(component_id, "attack_melee_damage_max")
    ComponentSetValue2(component_id, "attack_melee_damage_min", melee_damage_min * DAMAGE_MELEE_MULTIPLIER)
    ComponentSetValue2(component_id, "attack_melee_damage_max", melee_damage_max * DAMAGE_MELEE_MULTIPLIER)
  end
  local dash_enabled = ComponentGetValue2(component_id, "dash_enabled")
  if dash_enabled == true then
    local dash_damage = ComponentGetValue2(component_id, "attack_dash_damage")
    ComponentSetValue2(component_id, "attack_dash_damage", dash_damage * DAMAGE_MELEE_MULTIPLIER)
  end
end

function a13_elite_skills:add_shield(enemy_entity_id)
  -- log:debug("add_shield")

  local x, y = EntityGetTransform(enemy_entity_id)
  local child_id = EntityLoad("data/entities/misc/perks/shield.xml", x, y)
  EntityAddChild(enemy_entity_id, child_id)
  local _ = EntityAddComponent2(child_id, "LuaComponent", {
    script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a13_cleanup_orphan_entity.lua",
    remove_after_executed = true,
  })
end

function a13_elite_skills:add_area_damage(enemy_entity_id)
  -- log:debug("add_area_damage")

  local x, y = EntityGetTransform(enemy_entity_id)
  local child_id = EntityLoad("data/entities/misc/perks/contact_damage_enemy.xml", x, y)
  EntityAddChild(enemy_entity_id, child_id)
  local _ = EntityAddComponent2(child_id, "LuaComponent", {
    script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a13_cleanup_orphan_entity.lua",
    remove_after_executed = true,
  })
end

function a13_elite_skills:use_wand(enemy_entity_id)
  -- NOTE:
  -- I saw the free wand that wasn't held by an enemy.
  -- I could probably delete free wands, generate InventoryQuick in the Enemy Entity, and inject wand data directly.
  -- But I like the whimsical nature of Noita's scripts, so I won't rewrite this.
  -- This method refers to noita's nightmare mode
  -- log:debug("use_wand")

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

a13_elite_skills.projectile_skills = {
  a13_elite_skills.add_homing,
  a13_elite_skills.add_extra_projectile,
  a13_elite_skills.increase_projectile_fire_rate,
  a13_elite_skills.increase_projectile_damage,
  a13_elite_skills.increase_projectile_explosion,
  a13_elite_skills.increase_projectile_speed,
}

a13_elite_skills.body_skills = {
  a13_elite_skills.increase_hp,
  a13_elite_skills.increase_character_speed,
  a13_elite_skills.increase_melee_damage,
  a13_elite_skills.add_shield,
  a13_elite_skills.add_area_damage,
  a13_elite_skills.use_wand,
}

return a13_elite_skills
