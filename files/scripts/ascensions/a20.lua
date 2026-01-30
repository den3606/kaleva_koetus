-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

---@type Events
local Events = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/events.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local LevelTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 20
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a20.lua")

local a20_boss_died_key = LevelTags.A20 .. EventTypes.BOSS_DIED
local a20_sampo_tag = LevelTags.A20 .. "sampo_to_remove"

function ascension:on_mod_init()
  -- log:debug("new game plus")
  ModLuaFileAppend("data/entities/animals/boss_centipede/death_check.lua", "mods/kaleva_koetus/files/scripts/appends/death_check.lua")
  ModLuaFileAppend(
    "data/scripts/biomes/mountain/mountain_floating_island.lua",
    "mods/kaleva_koetus/files/scripts/appends/mountain_floating_island.lua"
  )
  ModLuaFileAppend("data/scripts/biome_map.lua", "mods/kaleva_koetus/files/scripts/appends/biome_map.lua")

  for content in nxml.edit_file("data/entities/animals/boss_centipede/sampo.xml") do
    content:create_child("LuaComponent", {
      script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a20_tag_sampo.lua",
      execute_on_added = "1",
      remove_after_executed = "1",
    })
  end

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

function ascension:on_new_game_plus_started()
  local player_entity_id = GetPlayerEntity()
  if player_entity_id == nil then
    return
  end

  local child_entities = EntityGetAllChildren(player_entity_id)
  if child_entities == nil then
    return
  end
  local inventory_quick_id
  local inventory_full_id
  for _, child_entity_id in ipairs(child_entities) do
    local name = EntityGetName(child_entity_id)
    if inventory_quick_id == nil and name == "inventory_quick" then
      inventory_quick_id = child_entity_id
    elseif inventory_full_id == nil and name == "inventory_full" then
      inventory_full_id = child_entity_id
    end
  end

  if inventory_quick_id then
    local targets = EntityGetAllChildren(inventory_quick_id, a20_sampo_tag)
    if targets and #targets > 0 then
      EntityKill(targets[1])
      return
    end
  end
  if inventory_full_id then
    local targets = EntityGetAllChildren(inventory_full_id, a20_sampo_tag)
    if targets and #targets > 0 then
      EntityKill(targets[1])
      return
    end
  end
end

return ascension
