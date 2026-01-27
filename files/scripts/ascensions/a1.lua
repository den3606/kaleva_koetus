local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 1
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

local log = Logger:new("a1.lua")

local hp_multiplier = 1.5
local a1_enemy_tag = AscensionTags.A1 .. EventTypes.ENEMY_POST_SPAWN

function ascension:on_mod_init()
  -- log:info("Enemy HP increase active (x%d)", self.hp_multiplier)
  local boss_centipede_lua_file = ModTextFileGetContent("data/entities/animals/boss_centipede/boss_centipede_update.lua")
  local before_boss_centipede_lua_file = ModTextFileGetContent("mods/kaleva_koetus/files/scripts/appends/boss_centipede_update_a1.lua")
  ModTextFileSetContent(
    "data/entities/animals/boss_centipede/boss_centipede_update.lua",
    before_boss_centipede_lua_file .. "\n" .. boss_centipede_lua_file
  )
end

function ascension:on_enemy_post_spawn(entity_id, _, _)
  if EntityHasTag(entity_id, a1_enemy_tag) then
    -- log:debug("Entity %d already processed, skipping", enemy_entity)
    return
  end

  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  if not damage_model then
    log:warn("No DamageModelComponent found for entity %d", entity_id)
    return
  end

  local current_hp = ComponentGetValue2(damage_model, "hp")
  local max_hp = ComponentGetValue2(damage_model, "max_hp")

  local new_hp = current_hp * hp_multiplier
  local new_max_hp = max_hp * hp_multiplier

  ComponentSetValue2(damage_model, "hp", new_hp)
  ComponentSetValue2(damage_model, "max_hp", new_max_hp)

  EntityAddTag(entity_id, a1_enemy_tag)

  -- log:verbose("Entity %d HP %.1f -> %.1f, MaxHP %.1f -> %.1f", enemy_entity, current_hp, new_hp, max_hp, new_max_hp)
end

return ascension
