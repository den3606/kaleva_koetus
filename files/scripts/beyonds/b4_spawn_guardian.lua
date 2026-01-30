local _ = dofile_once("data/scripts/biomes/temple_shared.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local LevelTags = EventDefs.Tags

if GlobalsGetValue("TEMPLE_SPAWN_GUARDIAN") == "1" then
  return
end

local b4_count_key = LevelTags.B4 .. "guardian_spawn_pos_count"

local b4_spawn_count = tonumber(GlobalsGetValue(b4_count_key)) or 0
if b4_spawn_count < 3 then
  b4_spawn_count = b4_spawn_count + 1
  GlobalsSetValue(b4_count_key, tostring(b4_spawn_count))
end

if b4_spawn_count < 3 then
  return
end

if GlobalsGetValue("TEMPLE_PEACE_WITH_GODS") == "1" then
  return
end

local entity_id = GetUpdatedEntityID()
local ex, ey = EntityGetTransform(entity_id)

-- selene: allow(undefined_variable)
temple_spawn_guardian(ex, ey)
GlobalsSetValue("TEMPLE_SPAWN_GUARDIAN", "1")

GamePrintImportant("$kaleva_koetus_b4_god_mood", "")
GamePlaySound("data/audio/Desktop/event_cues.bank", "event_cues/angered_the_gods/create", ex, ey)
GameScreenshake(150)
