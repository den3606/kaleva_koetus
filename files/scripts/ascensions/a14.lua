-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 14
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a14.lua")

local GOLD_LIFETIME_MULTIPLIER = 0.25

function ascension:on_mod_init()
  -- log:info("Gold lifetime will be half")
end

function ascension:on_gold_spawn(payload)
  -- log:debug("on_gold_spawn")
  local gold_entity_id = tonumber(payload[1])

  local lifetime_components = EntityGetComponent(gold_entity_id, "LifetimeComponent")
  if lifetime_components ~= nil then
    for _, lifetime_component_id in ipairs(lifetime_components) do
      local lifetime = ComponentGetValue2(lifetime_component_id, "lifetime")
      EntityRemoveComponent(gold_entity_id, lifetime_component_id)
      local _ = EntityAddComponent2(gold_entity_id, "LifetimeComponent", {
        _tags = "enabled_in_world",
        lifetime = math.floor(lifetime * GOLD_LIFETIME_MULTIPLIER),
      })
    end
  end
end

return ascension
