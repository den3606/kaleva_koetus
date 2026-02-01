-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

---@type Events
local Events = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/events.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local AscensionTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 20
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a20.lua")

local a20_boss_died_key = AscensionTags.A1 .. EventTypes.BOSS_DIED

function ascension:on_mod_init()
  -- log:debug("new game plus")
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
  if GlobalsGetValue(a20_boss_died_key, "0") == "1" then
    return
  end

  local _ = dofile_once("data/scripts/newgame_plus.lua")
  local p_x = tonumber(MagicNumbersGetValue("DESIGN_PLAYER_START_POS_X")) or 0
  local p_y = tonumber(MagicNumbersGetValue("DESIGN_PLAYER_START_POS_Y")) or 0

  local player = EntityGetWithTag("player_unit")[1]
  if player ~= nil then
    EntitySetTransform(player, p_x, p_y - 20)
  end
  -- selene: allow(undefined_variable)
  do_newgame_plus()
  GlobalsSetValue(a20_boss_died_key, "1")

  Events.queue.NEW_GAME_PLUS_STARTED()
end

function ascension:should_unlock_next()
  return false
end

return ascension
