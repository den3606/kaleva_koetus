-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local A13EliteSkills = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a13_elite_skills.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
-- local log = Logger:new("a13.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 13
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

local UPGRADE_CHANCE = 0.20

local a13_enemy_tag = AscensionTags.A13 .. EventTypes.ENEMY_POST_SPAWN

local function enemy_not_boss(entity_id)
  local tags = EntityGetTags(entity_id)
  if tags == nil then
    return false
  end
  local padded_tags = "," .. tags .. ","

  if string.find(padded_tags, ",%s*boss%s*,") then
    return false
  end
  if string.find(padded_tags, ",%s*boss_[^,]*%s*,") then
    return false
  end

  return true
end

local function random_unique_integers(min, max, count)
  min = min - 1
  local total = max - min
  local numbers = {}
  for i = 1, total do
    numbers[i] = i + min
  end

  for i = 1, count do
    local j = Random(i, total)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    result[i] = numbers[i]
  end

  return result
end

local function can_shot(enemy_entity_id)
  local component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "AnimalAIComponent")
  if not component_id then
    return
  end

  local attack_ranged_enabled = ComponentGetValue2(component_id, "attack_ranged_enabled")
  return attack_ranged_enabled
end

local function add_elite_effect(enemy_entity_id)
  local _ = EntityAddComponent2(enemy_entity_id, "ParticleEmitterComponent", {
    emitted_material_name = "spark_blue_dark",
    lifetime_min = 0.3,
    lifetime_max = 0.8,
    count_min = 12,
    count_max = 20,
    render_on_grid = false,
    fade_based_on_lifetime = true,
    cosmetic_force_create = false,
    airflow_force = 1.5,
    airflow_time = 1.9,
    airflow_scale = 0.15,
    emission_interval_min_frames = 1,
    emission_interval_max_frames = 1,
    emit_cosmetic_particles = true,
    draw_as_long = true,
    x_vel_min = -2,
    x_vel_max = 2,
    y_vel_min = -2,
    y_vel_max = 2,
    is_emitting = true,
  })

  local _ = EntityAddComponent2(enemy_entity_id, "ParticleEmitterComponent", {
    emitted_material_name = "spark_blue",
    emit_real_particles = true,
    emit_cosmetic_particles = true,
    emission_interval_min_frames = 1,
    emission_interval_max_frames = 10,
    count_min = 10,
    count_max = 20,
    x_pos_offset_min = -3,
    x_pos_offset_max = 3,
    y_pos_offset_min = -5,
    y_pos_offset_max = 1,
    y_vel_min = 0,
    y_vel_max = 0,
    airflow_force = 1,
    airflow_time = 1.9,
    airflow_scale = 0.15,
  })

  local _ = EntityAddComponent2(enemy_entity_id, "LightComponent", {
    radius = 150,
    r = 138,
    g = 43,
    b = 226,
  })
end

local function upgrade_enemy(enemy_entity_id, x, y)
  add_elite_effect(enemy_entity_id)

  -- 血をvoid waterに(must)
  local damage_model_component_id = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "DamageModelComponent")
  if damage_model_component_id ~= nil then
    ComponentSetValue2(damage_model_component_id, "blood_spray_material", "material_darkness")
    ComponentSetValue2(damage_model_component_id, "blood_material", "material_darkness")
  end

  SetRandomSeed(x + enemy_entity_id, y)
  if can_shot(enemy_entity_id) then
    local how_many_add_projectile_skill = Random(2, 3)
    local how_many_add_body_skill = Random(1, 3)

    local projectile_indexes = random_unique_integers(1, #A13EliteSkills.projectile_skills, how_many_add_projectile_skill)
    local body_indexes = random_unique_integers(1, #A13EliteSkills.body_skills, how_many_add_body_skill)

    for _, index in ipairs(projectile_indexes) do
      local func = A13EliteSkills.projectile_skills[index]
      func(A13EliteSkills, enemy_entity_id)
    end

    for _, index in ipairs(body_indexes) do
      local func = A13EliteSkills.body_skills[index]
      func(A13EliteSkills, enemy_entity_id)
    end
  else
    local how_many_add_body_skill = Random(3, 5)
    local body_indexes = random_unique_integers(1, #A13EliteSkills.body_skills, how_many_add_body_skill)

    for _, index in ipairs(body_indexes) do
      local func = A13EliteSkills.body_skills[index]
      func(A13EliteSkills, enemy_entity_id)
    end
  end

  EntityAddTag(enemy_entity_id, a13_enemy_tag)
  -- log:verbose("Upgrade enemy %d", enemy_entity_id)
end

function ascension:on_mod_init()
  -- log:info("Elite enemy spawns")
end

function ascension:on_enemy_post_spawn(entity_id, x, y)
  -- log:verbose("on_enemy_post_spawn")
  if entity_id == 0 then
    return
  end

  if EntityHasTag(entity_id, a13_enemy_tag) then
    return
  end

  if enemy_not_boss(entity_id) == false then
    return
  end

  local seed_x = math.floor(x)
  local seed_y = math.floor(y + GameGetFrameNum())
  SetRandomSeed(seed_x, seed_y)
  local randf = Randomf()
  if randf <= UPGRADE_CHANCE then
    upgrade_enemy(entity_id, x, y)
  end
end

return ascension
