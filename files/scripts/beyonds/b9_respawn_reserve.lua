---@meta ReserveRespawnIcons

---@type RespawnIcon
local RespawnIcon = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_icon.lua")

---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_add_variable_tag = VariableUtils.entity_add_variable_tag

local function reserve_all_respawn_icons(entity_id)
  local child_entities = EntityGetAllChildren(entity_id)
  if child_entities == nil then
    return
  end

  for _, child_entity_id in ipairs(child_entities) do
    if
      entity_has_variable_tag(child_entity_id, "kaleva_koetus_respawn_icon") == true
      and entity_has_variable_tag(child_entity_id, "kaleva_koetus_respawn_spent_icon") == false
    then
      local is_spent = RespawnIcon.reset_icon_entity(child_entity_id)
      if is_spent == true then
        entity_add_variable_tag(child_entity_id, "kaleva_koetus_respawn_spent_icon")
      end
    end
  end

  local script_path = "mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_restore.lua"
  local lua_components = EntityGetComponent(entity_id, "LuaComponent")
  if lua_components ~= nil then
    for _, lua_component_id in ipairs(lua_components) do
      local script_source_file = ComponentGetValue2(lua_component_id, "script_source_file")
      if script_source_file == script_path then
        ComponentSetValue2(lua_component_id, "mNextExecutionTime", GameGetFrameNum() + 1)
        return
      end
    end
  end
  local _ = EntityAddComponent2(entity_id, "LuaComponent", {
    script_source_file = script_path,
    execute_every_n_frame = 1,
    remove_after_executed = true,
  })
end

return reserve_all_respawn_icons
