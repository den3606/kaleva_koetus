local ascension = {}

-- Metadata
ascension.level = 0
ascension.name = "none"
ascension.description = "none"

function ascension:on_activate()
  print("on_activate is not implement")
end

function ascension:on_world_pre_update()
  print("on_world_pre_update is not implement")
end
function ascension:on_player_spawn()
  print("on_player_spawn is not implement")
end

function ascension:on_enemy_spawn(_enemy)
  print("on_enemy_spawn is not implement")
end

function ascension:should_unlock_next()
  return true
end

return ascension
