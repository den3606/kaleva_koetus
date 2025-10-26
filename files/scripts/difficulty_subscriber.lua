local difficulty = {}

local REQUIRED_FIELDS = {
  description = "description is not implement",
  specification = "specification is not implement",
  level = "level is not implement",
  tag_name = "difficulty tag_name is not implement",
}

setmetatable(difficulty, {
  __index = function(_, key)
    local message = REQUIRED_FIELDS[key]
    if message then
      error(message)
    end

    return nil
  end,
})

function difficulty:on_activate()
  error("on_activate is not implement")
end

function difficulty:should_unlock_next()
  return true
end

-- Optional
function difficulty:on_shop_card_spawn(_cards) end
-- Optional
function difficulty:on_shop_wand_spawn(_wands) end
-- Optional
function difficulty:on_world_pre_update() end
-- Optional
function difficulty:on_necromancer_spawn(_positions) end
-- Optional
function difficulty:on_player_spawn() end
-- Optional
function difficulty:on_mod_post_init() end
-- Optional
function difficulty:on_world_initialized() end
-- Optional
function difficulty:on_biome_config_loaded() end
-- Optional
function difficulty:on_enemy_spawn(_enemy) end
-- Optional
function difficulty:on_enemy_post_spawn(_enemy) end
-- Optional
function difficulty:on_potion_generated(_potion) end
-- Optional
function difficulty:on_book_generated(_book) end
-- Optional
function difficulty:on_gold_spawn() end
-- Optional
function difficulty:on_spell_generated(_spell) end
-- Optional
function difficulty:on_boss_died() end

function difficulty:on_new_game_plus_started() end

return difficulty
