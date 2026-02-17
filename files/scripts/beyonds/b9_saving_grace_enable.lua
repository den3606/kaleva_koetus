local json = dofile_once("mods/kaleva_koetus/files/scripts/lib/jsonlua/json.lua")
local base64 = dofile_once("mods/kaleva_koetus/files/scripts/lib/lbase64/base64.lua")

---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag

local entity_id = GetUpdatedEntityID()

local game_effect_components = EntityGetComponent(entity_id, "GameEffectComponent")
if game_effect_components ~= nil then
  for _, game_effect_component_id in ipairs(game_effect_components) do
    local effect = ComponentGetValue2(game_effect_component_id, "effect")
    if effect == "CUSTOM" then
      local custom_effect_id = ComponentGetValue2(game_effect_component_id, "custom_effect_id")
      if custom_effect_id == "SAVING_GRACE_COOLDOWN" then
        local frames = ComponentGetValue2(game_effect_component_id, "frames")
        if frames >= 0 then
          return
        end
        break
      end
    end
  end
end

local curr_component_id = GetUpdatedComponentID()
EntityRemoveComponent(entity_id, curr_component_id)

local parent_entity_id = EntityGetParent(entity_id)
if parent_entity_id == 0 then
  return
end

local child_entities = EntityGetAllChildren(parent_entity_id)
if child_entities == nil then
  return
end

for _, child_entity_id in ipairs(child_entities) do
  if entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_effect") == true then
    local components = EntityGetComponentIncludingDisabled(child_entity_id, "GameEffectComponent")
    if components ~= nil then
      for _, component_id in ipairs(components) do
        local effect = ComponentGetValue2(component_id, "effect")
        if effect == "SAVING_GRACE" then
          EntitySetComponentIsEnabled(child_entity_id, component_id, true)
        end
      end
    end
  elseif entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_icon") == true then
    local components = EntityGetComponentIncludingDisabled(child_entity_id, "VariableStorageComponent")
    if components ~= nil then
      for _, component_id in ipairs(components) do
        local name = ComponentGetValue2(component_id, "name")
        if name == "kaleva_koetus_serialized_ui_icon_component" then
          local value_string = ComponentGetValue2(component_id, "value_string")
          _ = EntityAddComponent2(child_entity_id, "UIIconComponent", json.decode(base64.decode(value_string)))
          EntityRemoveComponent(child_entity_id, component_id)
        end
      end
    end
  end
end
