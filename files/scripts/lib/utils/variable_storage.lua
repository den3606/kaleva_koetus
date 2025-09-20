-- 特定のEnitity内にあるVariableStorageComponentへ値をセットする
function SetInternalVariableValue(entity_id, variable_name, variable_type, new_value)

  local components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
  if (components ~= nil) then
    for key, comp_id in pairs(components) do
      local var_name = ComponentGetValue2(comp_id, "name")
      if (var_name == variable_name) then
        ComponentSetValue2(comp_id, variable_type, new_value)
      end
    end
  end
end

-- 特定のEnitity内にあるVariableStorageComponentへ値を取得する
function GetInternalVariableValue(entity_id, variable_name, variable_type)
  local value = nil
  local components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
  if (components ~= nil) then
    for key, comp_id in pairs(components) do
      local var_name = ComponentGetValue2(comp_id, "name")
      if (var_name == variable_name) then
        value = ComponentGetValue2(comp_id, variable_type)
      end
    end
  end
  return value
end

-- 特定のEnitity内にVariableStorageComponentを拡張する
-- 初期化時に値をセットできるため、値を複数回更新しない場合はこの関数のみの利用で問題なし
function AddNewInternalVariable(entity_id, variable_name, variable_type, initial_value)
  if (variable_type == "value_int") then
    EntityAddComponent2(entity_id, "VariableStorageComponent", {
      name = variable_name,
      value_int = initial_value,
    })
  elseif (variable_type == "value_string") then
    EntityAddComponent2(entity_id, "VariableStorageComponent", {
      name = variable_name,
      value_string = initial_value,
    })
  elseif (variable_type == "value_float") then
    EntityAddComponent2(entity_id, "VariableStorageComponent", {
      name = variable_name,
      value_float = initial_value,
    })
  elseif (variable_type == "value_bool") then
    EntityAddComponent2(entity_id, "VariableStorageComponent", {
      name = variable_name,
      value_bool = initial_value,
    })
  end
end

function RemoveInternalVariableValue(entity_id, variable_name, variable_type)
  local components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
  if (components ~= nil) then
    for key, comp_id in pairs(components) do
      local var_name = ComponentGetValue2(comp_id, "name")
      if (var_name == variable_name) then
        EntityRemoveComponent(entity_id, comp_id)
      end
    end
  end
end
