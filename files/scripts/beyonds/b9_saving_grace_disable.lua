local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")
local base64 = dofile_once("mods/kaleva_koetus/files/scripts/lib/lbase64/base64.lua")

local ui_icon_component_fields = {
  "icon_sprite_file",
  "name",
  "description",
  "display_above_head",
  "display_in_hud",
  "is_perk",
}
local function ui_icon_component_to_string(ui_icon_component_id)
  local table_of_component_values = {
    _enabled = ComponentGetIsEnabled(ui_icon_component_id),
    _tags = ComponentGetTags(ui_icon_component_id),
  }
  for _, field in ipairs(ui_icon_component_fields) do
    table_of_component_values[field] = ComponentGetValue2(ui_icon_component_id, field)
  end

  return base64.encode(json.encode(table_of_component_values))
end

---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_add_variable_tag = VariableUtils.entity_add_variable_tag

local entity_id = GetUpdatedEntityID()

local child_entities = EntityGetAllChildren(entity_id)
if child_entities == nil then
  return
end

local find_restore_entity = false

for _, child_entity_id in ipairs(child_entities) do
  if entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_effect") == true then
    local components = EntityGetComponent(child_entity_id, "GameEffectComponent")
    if components ~= nil then
      for _, component_id in ipairs(components) do
        local effect = ComponentGetValue2(component_id, "effect")
        if effect == "SAVING_GRACE" then
          EntitySetComponentIsEnabled(child_entity_id, component_id, false)
        end
      end
    end
  elseif entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_icon") == true then
    local components = EntityGetComponentIncludingDisabled(child_entity_id, "UIIconComponent")
    if components ~= nil then
      for _, component_id in ipairs(components) do
        _ = EntityAddComponent2(child_entity_id, "VariableStorageComponent", {
          name = "kaleva_koetus_serialized_ui_icon_component",
          value_string = ui_icon_component_to_string(component_id),
        })
        EntityRemoveComponent(child_entity_id, component_id)
      end
    end
  elseif entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_restore") == true then
    find_restore_entity = true
  end
end

if find_restore_entity == true then
  return
end

local x, y = EntityGetTransform(entity_id)
local restore_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/effect_saving_grace_cooldown.xml", x, y)
entity_add_variable_tag(restore_entity_id, "kaleva_koetus_saving_grace_restore")
EntityAddChild(entity_id, restore_entity_id)
