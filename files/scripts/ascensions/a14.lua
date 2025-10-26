-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

-- local log = Logger:new("a14.lua")

local GOLD_LIFETIME_MULTIPLIER = 0.25

ascension.level = 14
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A14 .. EventTypes.GOLD_SPAWN

function ascension:on_activate()
  -- log:info("Gold lifetime will be half")
end

function ascension:on_gold_spawn(payload)
  -- log:debug("on_gold_spawn")
  local gold_entity_id = tonumber(payload[1])
  local must_remove_timer = (payload[4] == "true")

  if must_remove_timer then
    return
  end

  local component_id = EntityGetFirstComponent(gold_entity_id, "LifetimeComponent")
  local lifetime = ComponentGetValue2(component_id, "lifetime")
  EntityRemoveComponent(gold_entity_id, component_id)
  local _ = EntityAddComponent2(gold_entity_id, "LifetimeComponent", {
    _tags = "enabled_in_world",
    lifetime = math.floor(lifetime * GOLD_LIFETIME_MULTIPLIER),
  })
end

return ascension
