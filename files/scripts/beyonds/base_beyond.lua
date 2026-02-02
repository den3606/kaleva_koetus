---@class Beyond
---@field level number
---@field description string
---@field specification string

---@class Beyond
---@field on_mod_init fun(self:Beyond)
---@field on_mod_post_init fun(self:Beyond)
---@field on_biome_config_loaded fun(self:Beyond)
---@field on_world_initialized fun(self:Beyond)
---@field on_player_spawned fun(self:Beyond, player_entity_id: number)
---@field on_world_pre_update fun(self:Beyond)
---@field on_world_post_update fun(self:Beyond)

---@class Beyond
---@field on_book_generated fun(self:Beyond, entity_id:number)
---@field on_boss_died fun(self:Beyond)
---@field on_enemy_post_spawn fun(self:Beyond, entity_id:number, x:number, y:number)
---@field on_enemy_spawn fun(self:Beyond, entity_id:number, x:number, y:number, mark_as_processed:function)
---@field on_gold_spawn fun(self:Beyond, entity_id:number)
---@field on_necromancer_spawn fun(self:Beyond, x:number, y:number)
---@field on_new_game_plus_started fun(self:Beyond)
---@field on_potion_generated fun(self:Beyond, entity_id:number)
---@field on_shop_card_spawn fun(self:Beyond, entity_ids:number[], x:number, y:number)
---@field on_shop_wand_spawn fun(self:Beyond, entity_ids:number[], x:number, y:number)
---@field on_victory fun(self:Beyond)
local beyond = {}
beyond.__index = beyond

return setmetatable({}, beyond)
