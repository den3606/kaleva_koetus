local DAMAGE_MULTIPLIER = 0.25

-- selene: allow(unused_variable)
function damage_about_to_be_received(damage, _x, _y, _entity_thats_responsible, critical_hit_chance)
  if damage >= 0 then
    damage = damage * DAMAGE_MULTIPLIER
  end
  return damage, critical_hit_chance
end
