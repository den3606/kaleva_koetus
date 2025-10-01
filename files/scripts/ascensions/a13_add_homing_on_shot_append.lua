local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("a13_add_homing_on_shot_append.lua")
local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/variable_storage.lua")

-- selene: allow(unused_variable)
function shot(projectile_entity_id)
  log:debug("elite enemy shot")

  local existing_component = EntityGetFirstComponentIncludingDisabled(projectile_entity_id, "HomingComponent")
  if existing_component then
    return
  end

  local _ = EntityAddComponent2(projectile_entity_id, "HomingComponent", {
    target_tag = "prey",
    homing_targeting_coeff = 10,
    detect_distance = 350,
    homing_velocity_multiplier = 1,
  })
end
