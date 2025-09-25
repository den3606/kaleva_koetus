local ascension = {}

local REQUIRED_FIELDS = {
  name = "name is not implement",
  description = "description is not implement",
  level = "level is not implement",
  tag_name = "ascension tag_name is not implement",
}

setmetatable(ascension, {
  __index = function(_, key)
    local message = REQUIRED_FIELDS[key]
    if message then
      error(message)
    end

    return nil
  end,
})

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

function ascension:on_necromancer_spawn(_positions)
  -- Optional
end

function ascension:on_player_spawn()
  -- Optional
end

function ascension:on_enemy_spawn(_enemy)
  -- Optional
end

function ascension:on_potion_generated(_potion)
  -- Optional
end

function ascension:on_book_generated(_book)
  -- Optional
end

return ascension
