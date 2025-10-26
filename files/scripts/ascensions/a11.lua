-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local DuplicateUtils = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/a11_entity_duplicate_utils.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a11.lua")

ascension.level = 11
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = DuplicateUtils.tag_name

local function enemy_not_boss(entity_id)
  local tags = EntityGetTags(entity_id)
  if tags == nil then
    return false
  end

  if DuplicateUtils.has_boss_tag(tags) then
    return false
  end

  return true
end

local function has_no_gold(entity_id)
  if EntityGetFirstComponent(entity_id, "VariableStorageComponent", "no_gold_drop") ~= nil then
    return true
  end

  local lua_components = EntityGetComponent(entity_id, "LuaComponent")
  if lua_components ~= nil then
    for _, lua_component in ipairs(lua_components) do
      if ComponentGetValue2(lua_component, "script_death") == "data/scripts/items/drop_money.lua" then
        return false
      end
    end
  end

  return true
end

local function add_no_gold(entity_id)
  local _ = EntityAddComponent2(entity_id, "VariableStorageComponent", { _tags = "no_gold_drop" })
end

function ascension:on_activate()
  -- log:info("Increasing enemy spawns")
  DuplicateUtils.build_duplicated_files_from_storage()
  ModLuaFileAppend("data/scripts/director_helpers.lua", "mods/kaleva_koetus/files/scripts/appends/director_helpers.lua")
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity_id = tonumber(payload[1])
  local x = tonumber(payload[2]) or 0
  local y = tonumber(payload[3]) or 0
  local mark_as_processed = payload[4]

  if not enemy_entity_id or enemy_entity_id == 0 then
    return
  end

  if EntityHasTag(enemy_entity_id, ascension.tag_name) then
    return
  end

  if enemy_not_boss(enemy_entity_id) == false then
    return
  end

  if EntityHasTag(enemy_entity_id, "polymorphed") then
    return
  end

  local entity_filename = EntityGetFilename(enemy_entity_id)
  if entity_filename == "" then
    return
  end

  local should_no_gold = has_no_gold(enemy_entity_id)

  if entity_filename == "data/entities/animals/apparition/playerghost.xml" then
    local children = EntityGetAllChildren(enemy_entity_id)
    if children ~= nil then
      for _, child_entity_id in ipairs(children) do
        if EntityGetName(child_entity_id) == "inventory_quick" then
          EntityAddTag(enemy_entity_id, ascension.tag_name)
          local how_many = DuplicateUtils.get_extra_count(x, y)
          for _ = 1, how_many, 1 do
            local offset_x = Random(-16, 16)
            local offset_y = Random(-16, 0)
            local _, apparition_entity_id = SpawnApparition(x + offset_x, y + offset_y, 0, true)
            EntityAddTag(apparition_entity_id, ascension.tag_name)
            if should_no_gold == true then
              add_no_gold(apparition_entity_id)
            end
          end
          return
        end
      end
    end
  end

  local duplicated_filename = DuplicateUtils.get_duplicated_filename(entity_filename)

  mark_as_processed(enemy_entity_id)
  EntityKill(enemy_entity_id)
  local new_entity_id = EntityLoad(duplicated_filename, x, y)
  should_no_gold = should_no_gold and has_no_gold(new_entity_id) == false
  if should_no_gold == true then
    add_no_gold(new_entity_id)
  end

  local how_many = DuplicateUtils.get_extra_count(x, y)
  for _ = 1, how_many, 1 do
    local offset_x = Random(-16, 16)
    local offset_y = Random(-16, 0)
    new_entity_id = EntityLoad(duplicated_filename, x + offset_x, y + offset_y)
    if should_no_gold == true then
      add_no_gold(new_entity_id)
    end
  end
end

return ascension
