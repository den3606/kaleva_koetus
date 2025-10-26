-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.AscensionTags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a19.lua")

ascension.level = 19
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A19

function ascension:on_activate()
  -- log:info("Boss HP increase active (x%d)", self.hp_multiplier)
  local boss_centipede_lua_file = ModTextFileGetContent("data/entities/animals/boss_centipede/boss_centipede_update.lua")
  local before_boss_centipede_lua_file = ModTextFileGetContent("mods/kaleva_koetus/files/scripts/appends/boss_centipede_update_a19.lua")
  ModTextFileSetContent(
    "data/entities/animals/boss_centipede/boss_centipede_update.lua",
    before_boss_centipede_lua_file .. "\n" .. boss_centipede_lua_file
  )
end

return ascension
