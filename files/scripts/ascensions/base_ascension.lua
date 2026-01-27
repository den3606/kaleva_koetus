---@class Ascension
---@field level number
---@field description string
---@field specification string

---@class Ascension
---@field on_mod_init function?
---@field on_mod_post_init function?
---@field on_biome_config_loaded function?
---@field on_world_initialized function?
---@field on_player_spawned fun(self:Ascension, player_entity_id: integer)
---@field on_world_pre_update function?

---@class Ascension
---@field on_book_generated function?
---@field on_boss_died function?
---@field on_enemy_post_spawn function?
---@field on_enemy_spawn function?
---@field on_gold_spawn function?
---@field on_necromancer_spawn function?
---@field on_new_game_plus_started function?
---@field on_potion_generated function?
---@field on_shop_card_spawn function?
---@field on_shop_wand_spawn function?
---@field on_victory function?
local ascension = {}

function ascension:should_unlock_next()
  return true
end

return ascension
