local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local TARGET_TAGS = { "tablet", "tablet_stone" }

local log = Logger:bind("A8")

ascension.level = 8
ascension.name = "石板なし"
ascension.description = "石板が出現しない"

local function purge_tablets()
  for _, tag in ipairs(TARGET_TAGS) do
    local entity_ids = EntityGetWithTag(tag)
    if entity_ids then
      for _, entity_id in ipairs(entity_ids) do
        EntityKill(entity_id)
      end
    end
  end
end

function ascension:on_activate()
  log:info("Preventing tablet spawns")
  purge_tablets()
end

function ascension:on_update()
  purge_tablets()
end

return ascension
