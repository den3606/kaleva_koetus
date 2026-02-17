---@class VariableUtils
local VariableUtils = {}

local tag_of_variable_storage = "kaleva_koetus_storage_variable"

---@param entity_id number
---@param name string
---@return number?
local function entity_get_variable_storage(entity_id, name)
  local variable_storage_components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent", tag_of_variable_storage)
  if variable_storage_components == nil then
    return nil
  end

  for _, variable_storage_component_id in ipairs(variable_storage_components) do
    local component_value_name = ComponentGetValue2(variable_storage_component_id, "name")
    if component_value_name == name then
      return variable_storage_component_id
    end
  end

  return nil
end

VariableUtils.entity_get_variable_storage = entity_get_variable_storage

---@param entity_id number
---@param name string
---@return number
function VariableUtils.entity_add_variable_storage(entity_id, name)
  local variable_component_id = entity_get_variable_storage(entity_id, name)
  if variable_component_id ~= nil then
    return variable_component_id
  end

  return EntityAddComponent2(entity_id, "VariableStorageComponent", {
    _tags = tag_of_variable_storage,
    name = name,
  })
end

local tag_of_variable_tag = "kaleva_koetus_tag_variable"

---@param entity_id number
---@param tag string
---@return boolean
function VariableUtils.entity_has_variable_tag(entity_id, tag)
  local variable_storage_components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent", tag_of_variable_tag)
  if variable_storage_components == nil then
    return false
  end

  for _, variable_storage_component_id in ipairs(variable_storage_components) do
    local name = ComponentGetValue2(variable_storage_component_id, "name")
    if name == tag then
      return true
    end
  end

  return false
end

---@param entity_id number
---@param tag string
---@return number?
local function entity_get_variable_tag(entity_id, tag)
  local variable_storage_components = EntityGetComponentIncludingDisabled(entity_id,
    "VariableStorageComponent", tag_of_variable_tag)
  if variable_storage_components == nil then
    return nil
  end

  for _, variable_storage_component_id in ipairs(variable_storage_components) do
    local name = ComponentGetValue2(variable_storage_component_id, "name")
    if name == tag then
      return variable_storage_component_id
    end
  end

  return nil
end

VariableUtils.entity_get_variable_tag = entity_get_variable_tag

---@param entity_id number
---@param tag string
---@return number
function VariableUtils.entity_add_variable_tag(entity_id, tag)
  local variable_component_id = entity_get_variable_tag(entity_id, tag)
  if variable_component_id ~= nil then
    return variable_component_id
  end

  return EntityAddComponent2(entity_id, "VariableStorageComponent", {
    _tags = tag_of_variable_tag,
    name = tag,
  })
end

---@param entity_id number
---@param tag string
---@return boolean was_removed
function VariableUtils.entity_remove_variable_tag(entity_id, tag)
  local variable_component_id = entity_get_variable_tag(entity_id, tag)
  if variable_component_id ~= nil then
    EntityRemoveComponent(entity_id, variable_component_id)
    return true
  end

  return false
end

return VariableUtils
