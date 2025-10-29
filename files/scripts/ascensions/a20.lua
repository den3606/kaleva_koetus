-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a20.lua")

ascension.level = 20
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A20

function ascension:on_activate()
  -- log:debug("new game plus")
  ModSettingSet("kaleva_koetus.a20_dead_boss", false)
  ModLuaFileAppend("data/entities/animals/boss_centipede/death_check.lua", "mods/kaleva_koetus/files/scripts/appends/death_check.lua")
  ModLuaFileAppend(
    "data/scripts/biomes/mountain/mountain_floating_island.lua",
    "mods/kaleva_koetus/files/scripts/appends/mountain_floating_island.lua"
  )
  ModLuaFileAppend("data/scripts/biome_map.lua", "mods/kaleva_koetus/files/scripts/appends/biome_map.lua")

  if ModIsEnabled("nightmare") then
    ModLuaFileAppend(
      "data/entities/animals/boss_centipede/rewards/spawn_rewards.lua",
      "mods/kaleva_koetus/files/scripts/appends/spawn_rewards_nightmare_a20.lua"
    )
  else
    ModLuaFileAppend(
      "data/entities/animals/boss_centipede/rewards/spawn_rewards.lua",
      "mods/kaleva_koetus/files/scripts/appends/spawn_rewards_a20.lua"
    )
  end
end

function ascension:on_boss_died()
  -- log:debug("a20 on_boss_died")
  if ModSettingGet("kaleva_koetus.a20_dead_boss") then
    return
  end

  local _ = dofile_once("data/scripts/newgame_plus.lua")
  local p_x = MagicNumbersGetValue("DESIGN_PLAYER_START_POS_X")
  local p_y = MagicNumbersGetValue("DESIGN_PLAYER_START_POS_Y")

  local player = EntityGetWithTag("player_unit")[1]
  if player ~= nil then
    EntitySetTransform(player, p_x, p_y - 20)
  end
  -- selene: allow(undefined_variable)
  do_newgame_plus()
  ModSettingSet("kaleva_koetus.a20_dead_boss", true)

  local EventTypes = EventDefs.Types
  local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")
  EventBroker:publish_event_sync("a20", EventTypes.NEW_GAME_PLUS_STARTED)
end

function ascension:should_unlock_next()
  return false
end

return ascension
