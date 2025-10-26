local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local BeyondBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local BeyondTags = EventDefs.BeyondTags

local beyond = setmetatable({}, { __index = BeyondBase })

local log = Logger:new("b1.lua")

beyond.level = 1
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level
beyond.hp_multiplier = 2.5
beyond.tag_name = BeyondTags.B1 .. EventTypes.ENEMY_POST_SPAWN

function beyond:on_activate()
  local boss_centipede_lua_file = ModTextFileGetContent("data/entities/animals/boss_centipede/boss_centipede_update.lua")
  local before_boss_centipede_lua_file = ModTextFileGetContent("mods/kaleva_koetus/files/scripts/appends/boss_centipede_update_b1.lua")
  ModTextFileSetContent(
    "data/entities/animals/boss_centipede/boss_centipede_update.lua",
    before_boss_centipede_lua_file .. "\n" .. boss_centipede_lua_file
  )
end

function beyond:on_enemy_post_spawn(payload)
  local enemy_entity = tonumber(payload[1])
  if not enemy_entity then
    return
  end

  if EntityHasTag(enemy_entity, beyond.tag_name) then
    return
  end

  local damage_model = EntityGetFirstComponent(enemy_entity, "DamageModelComponent")
  if not damage_model then
    log:warn("No DamageModelComponent found for entity %d", enemy_entity)
    return
  end

  local current_hp = ComponentGetValue2(damage_model, "hp")
  local max_hp = ComponentGetValue2(damage_model, "max_hp")

  local new_hp = current_hp * self.hp_multiplier
  local new_max_hp = max_hp * self.hp_multiplier

  ComponentSetValue2(damage_model, "hp", new_hp)
  ComponentSetValue2(damage_model, "max_hp", new_max_hp)

  EntityAddTag(enemy_entity, beyond.tag_name)

  log:verbose("Entity %d HP %.1f -> %.1f, MaxHP %.1f -> %.1f", enemy_entity, current_hp, new_hp, max_hp, new_max_hp)
end

return beyond
