local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 1
ascension.name = "敵HP上昇"
ascension.description = "敵のHPが1.5倍に増加"
ascension.hp_multiplier = 1.5

function ascension:on_activate()
  print("[Kaleva Koetus A1] Enemy HP increase - Active (x" .. self.hp_multiplier .. ")")
end

function ascension:on_enemy_spawn(event_args)
  -- event_args: {entity_id, x, y}
  if #event_args < 1 then
    return
  end

  local enemy_entity = tonumber(event_args[1])
  if not enemy_entity then
    return
  end

  local tag_name = AscensionTags.A1 .. EventTypes.ENEMY_SPAWN
  if EntityHasTag(enemy_entity, tag_name) then
    print("[Kaleva Koetus A1] Entity " .. enemy_entity .. " already processed, skipping")
    return
  end

  local damage_model = EntityGetFirstComponent(enemy_entity, "DamageModelComponent")
  if damage_model then
    local current_hp = ComponentGetValue2(damage_model, "hp")
    local max_hp = ComponentGetValue2(damage_model, "max_hp")

    local new_hp = current_hp * self.hp_multiplier
    local new_max_hp = max_hp * self.hp_multiplier

    ComponentSetValue2(damage_model, "hp", new_hp)
    ComponentSetValue2(damage_model, "max_hp", new_max_hp)

    EntityAddTag(enemy_entity, tag_name)

    print(
      string.format("[Kaleva Koetus A1] Entity %d: HP %.1f->%.1f, MaxHP %.1f->%.1f", enemy_entity, current_hp, new_hp, max_hp, new_max_hp)
    )
  else
    print("[Kaleva Koetus A1] No DamageModelComponent found for entity " .. enemy_entity)
  end
end

return ascension
