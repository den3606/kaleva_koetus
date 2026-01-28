---@class Ascension
---@field level number
---@field description string
---@field specification string

---@class Ascension
---@field on_mod_init fun(self:Ascension)
---@field on_mod_post_init fun(self:Ascension)
---@field on_biome_config_loaded fun(self:Ascension)
---@field on_world_initialized fun(self:Ascension)
---@field on_player_spawned fun(self:Ascension, player_entity_id: number)
---@field on_world_pre_update fun(self:Ascension)

---@class Ascension
---@field on_book_generated fun(self:Ascension, entity_id:number)
---@field on_boss_died fun(self:Ascension)
---@field on_enemy_post_spawn fun(self:Ascension, entity_id:number, x:number, y:number)
---@field on_enemy_spawn fun(self:Ascension, entity_id:number, x:number, y:number, mark_as_processed:function)
---@field on_gold_spawn fun(self:Ascension, entity_id:number)
---@field on_necromancer_spawn fun(self:Ascension, x:number, y:number)
---@field on_new_game_plus_started fun(self:Ascension)
---@field on_potion_generated fun(self:Ascension, entity_id:number)
---@field on_shop_card_spawn fun(self:Ascension, entity_ids:number[], x:number, y:number)
---@field on_shop_wand_spawn fun(self:Ascension, entity_ids:number[], x:number, y:number)
---@field on_victory fun(self:Ascension)
local ascension = {}

function ascension:should_unlock_next()
  return true
end

return ascension
