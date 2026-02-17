---@type RespawnIcon
local RespawnIcon = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_icon.lua")

---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_add_variable_tag = VariableUtils.entity_add_variable_tag

local entity_id = GetUpdatedEntityID()

local child_entities = EntityGetAllChildren(entity_id)
if child_entities == nil then
  return
end

for _, child_entity_id in ipairs(child_entities) do
  if
    entity_has_variable_tag(child_entity_id, "kaleva_koetus_respawn_icon") == true
    and entity_has_variable_tag(child_entity_id, "kaleva_koetus_respawn_spent_icon") == false
  then
    local is_spent = RespawnIcon.modify_icon_entity(child_entity_id)
    if is_spent == true then
      entity_add_variable_tag(child_entity_id, "kaleva_koetus_respawn_spent_icon")
    end
  end
end
