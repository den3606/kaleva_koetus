-- selene: allow(unused_variable)
function enabled_changed(entity_id, is_enabled)
  if is_enabled == true then
    return
  end

  local root = EntityGetRootEntity(entity_id)

  local variable_components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
  if variable_components == nil then
    return
  end

  for _, variable_component_id in ipairs(variable_components) do
    local name = ComponentGetValue2(variable_component_id, "name")
    if name == "player_entity_id" then
      ComponentSetValue2(variable_component_id, "value_int", root)
      _ = EntityAddComponent2(entity_id, "LuaComponent", {
        _tags = "enabled_in_world",
        script_source_file = "mods/kaleva_koetus/files/scripts/items/keep_inventory.lua",
        execute_every_n_frame = 0,
        remove_after_executed = true,
      })
      break
    end
  end
end
