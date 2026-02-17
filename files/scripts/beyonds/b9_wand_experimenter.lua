-- selene: allow(unused_variable)
function wand_fired(wand_entity_id)
  local ability_component_id = EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
  if ability_component_id == nil then
    return
  end

  local edit_count = ComponentGetValue2(ability_component_id, "stat_times_player_has_edited")
  if edit_count > 0 then
    return
  end

  local shot_count = ComponentGetValue2(ability_component_id, "stat_times_player_has_shot")
  if shot_count < 5 then
    ComponentSetValue2(ability_component_id, "stat_times_player_has_shot", 5)
  end
end
