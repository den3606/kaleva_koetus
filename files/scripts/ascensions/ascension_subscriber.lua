local ascension = {}

-- Metadata
ascension.level = 0
ascension.name = (function()
  error("name is not implement")
end)()

ascension.description = (function()
  error("description is not implement")
end)()

function ascension:on_activate()
  error("on_activate is not implement")
end

function ascension:should_unlock_next()
  return true
end

function ascension:on_shop_card_spawn(_cards)
  -- Optional
end

function ascension:on_shop_wand_spawn(_wands)
  -- Optional
end

function ascension:on_world_pre_update()
  -- Optional
end
function ascension:on_player_spawn()
  -- Optional
end

function ascension:on_enemy_spawn(_enemy)
  -- Optional
end

return ascension
