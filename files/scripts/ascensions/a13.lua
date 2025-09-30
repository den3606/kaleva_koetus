local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a13.lua")

local UPGRADE_CHANCE = 0.20

ascension.level = 13
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A13 .. EventTypes.ENEMY_SPAWN
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
    b = 226, -- 赤色など
  })
end

local function upgrade_enemy(enemy_entity_id, x, y)
  add_elite_effect(enemy_entity_id)

  -- ランダムで何個か付与する？
  -- ホーミングがなかったらホーミング付与
  -- 発射スピード強化
  -- 爆発強化
  -- 火力強化
  -- HPx1.5
  -- 血をvoid waterに(must)
  local offset_x = Random(-16, 16)
  local offset_y = Random(-16, 0)

  EntityAddTag(enemy_entity_id, ascension.tag_name)
  log:verbose("Upgrade enemy %d", enemy_entity_id)
end

function ascension:on_activate()
  log:info("Increasing enemy spawns")
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity_id = tonumber(payload[1])
  local x = tonumber(payload[2]) or 0
  local y = tonumber(payload[3]) or 0

  if not enemy_entity_id or enemy_entity_id == 0 then
    return
  end

  if EntityHasTag(enemy_entity_id, ascension.tag_name) then
    return
  end

  local seed_x = math.floor(x)
  local seed_y = math.floor(y + GameGetFrameNum())
  SetRandomSeed(seed_x, seed_y)
  local randf = Randomf()
  if randf <= UPGRADE_CHANCE then
    upgrade_enemy(enemy_entity_id, x, y)
  end
end

return ascension
