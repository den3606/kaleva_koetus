local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("A4.lua")

ascension.level = 4
ascension.name = "Ascension 4"
ascension.description = "神は今、虫の居所が悪いようです"
ascension.tag_name = AscensionTags.A4 .. EventTypes.NECROMANCER_SPAWN

function ascension:on_activate()
  log:info("Divine retribution enabled")
end

function ascension:on_player_spawn()
  GlobalsSetValue("STEVARI_DEATHS", tostring(2))
end

function ascension:on_necromancer_spawn(payload)
  local x = tonumber(payload[1])
  local y = tonumber(payload[2])

  if not x or not y then
    log:warn("Invalid necromancer spawn payload")
    return
  end

  log:debug("Summoning guardians at %d,%d", x, y)

  local thunder_skull_id = EntityLoad("data/entities/animals/thunderskull.xml", x - 20, y)
  if thunder_skull_id then
    EntityAddTag(thunder_skull_id, ascension.tag_name)
  end

  local ice_skull_id = EntityLoad("data/entities/animals/iceskull.xml", x + 20, y)
  if ice_skull_id then
    EntityAddTag(ice_skull_id, ascension.tag_name)
  end
end

return ascension
