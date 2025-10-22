local DuplicateUtils = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a11_entity_duplicate_utils.lua")

local EntityLoadCameraBound_origin = EntityLoadCameraBound

local function has_enemy_tag(tags)
  local padded_tags = "," .. tags .. ","

  if string.find(padded_tags, ",%s*enemy%s*,") then
    return true
  end

  return false
end

local function file_not_boss_enemy(elem)
  local tags = elem:get("tags")
  if tags == nil then
    return false
  end

  if has_enemy_tag(tags) == false then
    return false
  end

  if DuplicateUtils.has_boss_tag(tags) == true then
    return false
  end

  for genome_data_component in elem:each_of("GenomeDataComponent") do
    local _enabled = genome_data_component:get("_enabled")
    if _enabled == nil or _enabled == "1" then
      local herd_id = genome_data_component:get("herd_id")
      if herd_id == nil or herd_id == "player" then
        return false
      end
    end
  end

  return true
end

-- selene: allow(unused_variable)
function EntityLoadCameraBound(filename, pos_x, pos_y)
  local duplicated_filename = DuplicateUtils.get_duplicated_filename(filename, file_not_boss_enemy)
  if duplicated_filename == "" then
    EntityLoadCameraBound_origin(filename, pos_x, pos_y)
    return
  end

  EntityLoadCameraBound_origin(duplicated_filename, pos_x, pos_y)

  local how_many = DuplicateUtils.get_extra_count(pos_x, pos_y)
  for _ = 1, how_many, 1 do
    local offset_x = Random(-16, 16)
    local offset_y = Random(-16, 0)
    EntityLoadCameraBound_origin(duplicated_filename, pos_x + offset_x, pos_y + offset_y)
  end
end
