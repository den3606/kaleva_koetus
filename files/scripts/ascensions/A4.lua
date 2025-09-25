local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A4")

ascension.level = 4
ascension.name = "Ascension 4"
ascension.description = "神の虫の居所が悪くなる"

function ascension:on_activate()
  log:info("Divine retribution enabled")
end

function ascension:on_player_spawn()
  GlobalsSetValue("STEVARI_DEATHS", tostring(2))
end

function ascension:on_necromancer_spawn(payload)
  local x = tonumber(payload[1])
  local y = tonumber(payload[2])

  log:debug("Summoning guardians at %d,%d", x or -1, y or -1)

  local tag_name = AscensionTags.A4 .. EventTypes.ENEMY_SPAWN

  local thunder_skull_id = EntityLoad("data/entities/animals/thunderskull.xml", x - 20, y)
  EntityAddTag(thunder_skull_id, tag_name)
  local ice_skull_id = EntityLoad("data/entities/animals/iceskull.xml", x + 20, y)
  EntityAddTag(ice_skull_id, tag_name)
end

return ascension
