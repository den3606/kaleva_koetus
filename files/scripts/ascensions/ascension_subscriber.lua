local ascension = {}

-- Metadata
ascension.level = 0
ascension.name = "none"
ascension.description = "none"

function ascension:on_activate()
  error("on_activate is not implement")
end

function ascension:on_spawn_shop_item()
  error("on_spawn_shop_item is not implement")
end

function ascension:on_world_pre_update()
  error("on_world_pre_update is not implement")
end
function ascension:on_player_spawn()
  error("on_player_spawn is not implement")
end

function ascension:on_enemy_spawn(_enemy)
  error("on_enemy_spawn is not implement")
end

function ascension:should_unlock_next()
  return true
end

return ascension
