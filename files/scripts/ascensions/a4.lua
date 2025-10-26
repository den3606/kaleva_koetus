local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a4.lua")

ascension.level = 4
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A4 .. EventTypes.NECROMANCER_SPAWN

function ascension:on_activate()
  -- log:info("Divine retribution enabled")
end

function ascension:on_player_spawn()
  if GlobalsGetValue(ascension.tag_name, "0") == "1" then
    return
  end

  GlobalsSetValue("STEVARI_DEATHS", tostring(2))

  GlobalsSetValue(ascension.tag_name, "1")
end

function ascension:on_necromancer_spawn(payload)
  local x = tonumber(payload[1])
  local y = tonumber(payload[2])

  if not x or not y then
    log:warn("Invalid necromancer spawn payload")
    return
  end

  -- log:debug("Summoning guardians at %d,%d", x, y)

  local _ = EntityLoad("data/entities/animals/thunderskull.xml", x - 20, y)
  _ = EntityLoad("data/entities/animals/iceskull.xml", x + 20, y)
end

return ascension
