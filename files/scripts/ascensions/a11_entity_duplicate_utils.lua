local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local nxml_helper = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/nxml_helper.lua")

local DuplicateUtils = {}

local SPAWN_CHANCE_1 = 0.25
local SPAWN_CHANCE_2 = 0.10
local SPAWN_CHANCE_3 = 0.05

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
DuplicateUtils.tag_name = AscensionTags.A11 .. EventTypes.ENEMY_SPAWN

function DuplicateUtils.has_boss_tag(tags)
  local padded_tags = "," .. tags .. ","

  if string.find(padded_tags, ",%s*boss%s*,") then
    return true
  end

  if string.find(padded_tags, ",%s*boss_[^,]*%s*,") then
    return true
  end

  return false
end

local error_tracker = nxml_helper.create_tracker_ignoring({ "duplicate_attribute" })

local XML_ENTITY_WRAPPER_WITH_NAME = [[<Entity tags="%s" name="%s">
%s
</Entity>
]]
local XML_ENTITY_WRAPPER = [[<Entity tags="%s">
%s
</Entity>
]]
local XML_BASE_WRAPPER_WITH_CBC = [[  <Base file="%s" include_children="1">
    <CameraBoundComponent
      max_count="%d">
    </CameraBoundComponent>
  </Base>]]
local XML_BASE_WRAPPER = [[  <Base file="%s" include_children="1" />]]
local function get_duplicated_file_content(filename, should_duplicate)
  error_tracker.reset()
  local elem = nxml_helper.use_error_handler(nxml, error_tracker.error_handler, function()
    local parsed_elem = nxml.parse_file(filename)
    parsed_elem:expand_base()
    return parsed_elem
  end)
  if error_tracker.has_critical_error() == true then
    return nil
  end

  if should_duplicate ~= nil and should_duplicate(elem) == false then
    return nil
  else
    local base_elem
    local camera_bound_component = elem:first_of("CameraBoundComponent")
    if camera_bound_component ~= nil then
      local max_count = camera_bound_component:get("max_count")
      local max_count_value = tonumber(max_count) or 10
      base_elem = string.format(XML_BASE_WRAPPER_WITH_CBC, filename, max_count_value * 4)
    else
      base_elem = string.format(XML_BASE_WRAPPER, filename)
    end
    local entity_name = elem:get("name")
    if entity_name ~= nil then
      return string.format(XML_ENTITY_WRAPPER_WITH_NAME, DuplicateUtils.tag_name, entity_name, base_elem)
    else
      return string.format(XML_ENTITY_WRAPPER, DuplicateUtils.tag_name, base_elem)
    end
  end
end

local duplicated_file_storage_key = "kaleva_koetus.a11_duplicated_files"
local ModTextFileSetContent = ModTextFileSetContent

local cached_filename = {}
function DuplicateUtils.get_duplicated_filename(filename, should_duplicate)
  if cached_filename[filename] == nil then
    local duplicated_files_data = ModSettingGet(duplicated_file_storage_key)
    local duplicated_files
    if duplicated_files_data == nil then
      duplicated_files = {}
    else
      duplicated_files = json.decode(duplicated_files_data)
    end

    for origin_filename, related_filename in pairs(duplicated_files) do
      cached_filename[origin_filename] = related_filename
    end

    if cached_filename[filename] == nil then
      local related_filename = "mods/kaleva_koetus/a11/" .. filename
      local file_content = get_duplicated_file_content(filename, should_duplicate)
      if file_content == nil then
        cached_filename[filename] = ""
      else
        ModTextFileSetContent(related_filename, file_content)
        cached_filename[filename] = related_filename

        duplicated_files[filename] = related_filename
        local json_content = json.encode(duplicated_files)
        ModSettingSet(duplicated_file_storage_key, json_content)
      end
    end
  end

  return cached_filename[filename]
end

function DuplicateUtils.build_duplicated_files_from_storage()
  if SessionNumbersGetValue("is_biome_map_initialized") == "0" then
    local _ = ModSettingRemove(duplicated_file_storage_key)
    return
  end
  local duplicated_files_data = ModSettingGet(duplicated_file_storage_key)
  local duplicated_files = json.decode(duplicated_files_data)
  for origin_filename, related_filename in pairs(duplicated_files) do
    local file_content = get_duplicated_file_content(origin_filename) or ""
    ModTextFileSetContent(related_filename, file_content)
  end
end

function DuplicateUtils.get_extra_count(x, y)
  SetRandomSeed(x, y + GameGetFrameNum())
  local randf = Randomf()
  if randf <= SPAWN_CHANCE_3 then
    return 3
  elseif randf <= SPAWN_CHANCE_2 then
    return 2
  elseif randf <= SPAWN_CHANCE_1 then
    return 1
  else
    return 0
  end
end

return DuplicateUtils
