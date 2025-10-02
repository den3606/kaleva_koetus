local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
local log = Logger:new("a15.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 15
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A15 .. EventTypes.SPELL_GENERATED

local RISK_OF_BREAK = 0.5

local function random_unique_integers(min, max, count)
  local numbers = {}
  for i = min, max do
    table.insert(numbers, i)
  end

  -- Fisher-Yates shuffle
  for i = #numbers, 2, -1 do
    local j = Random(1, i)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    table.insert(result, numbers[i])
  end

  return result
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

local function break_spell(enemy_entity_id, x, y)
  add_elite_effect(enemy_entity_id)
  -- if can_shot(enemy_entity_id) then
  --   local how_many_add_projectile_skill = Random(2, 3)
  --   local how_many_add_body_skill = Random(1, 3)

  --   local projectile_indexes = random_unique_integers(1, #A13EliteSkills.projectile_skills, how_many_add_projectile_skill)
  --   local body_indexes = random_unique_integers(1, #A13EliteSkills.body_skills, how_many_add_body_skill)

  --   for _, index in ipairs(projectile_indexes) do
  --     local func = A13EliteSkills.projectile_skills[index]
  --     func(A13EliteSkills, enemy_entity_id)
  --   end

  --   for _, index in ipairs(body_indexes) do
  --     local func = A13EliteSkills.body_skills[index]
  --     func(A13EliteSkills, enemy_entity_id)
  --   end
  -- else
  --   local how_many_add_body_skill = Random(3, 5)
  --   local body_indexes = random_unique_integers(1, #A13EliteSkills.body_skills, how_many_add_body_skill)

  --   for _, index in ipairs(body_indexes) do
  --     local func = A13EliteSkills.body_skills[index]
  --     func(A13EliteSkills, enemy_entity_id)
  --   end
  -- end

  EntityAddTag(enemy_entity_id, ascension.tag_name)
  log:verbose("Upgrade enemy %d", enemy_entity_id)
end

function ascension:on_activate()
  log:info("Broken spells")
end

function ascension:on_spell_generated(payload)
  local spell_entity_id = tonumber(payload[1])

  if not spell_entity_id or spell_entity_id == 0 or EntityHasTag(spell_entity_id, ascension.tag_name) then
    return
  end

  local x, y = EntityGetTransform(spell_entity_id)
  SetRandomSeed(x, y + GameGetFrameNum())
  local randf = Randomf()
  if randf < RISK_OF_BREAK then
    break_spell(spell_entity_id, x, y)
  end
end

return ascension
