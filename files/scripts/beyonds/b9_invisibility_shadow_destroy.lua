local player_shadow_entities = EntityGetInRadiusWithTag(0, 0, math.huge, "kaleva_koetus_player_shadow")
for _, player_shadow_entity_id in ipairs(player_shadow_entities) do
  EntityKill(player_shadow_entity_id)
end
