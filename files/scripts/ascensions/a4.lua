-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 4
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a4.lua")

local a4_necromancer_key = AscensionTags.A4 .. EventTypes.NECROMANCER_SPAWN

function ascension:on_mod_init()
  -- log:info("Divine retribution enabled")
end

function ascension:on_world_initialized()
  if GlobalsGetValue(a4_necromancer_key, "0") == "1" then
    return
  end

  GlobalsSetValue("STEVARI_DEATHS", tostring(2))

  GlobalsSetValue(a4_necromancer_key, "1")
end

function ascension:on_necromancer_spawn(x, y)
  -- log:debug("Summoning guardians at %d,%d", x, y)
  local _ = EntityLoad("data/entities/animals/thunderskull.xml", x - 20, y)
  _ = EntityLoad("data/entities/animals/iceskull.xml", x + 20, y)
end

return ascension
