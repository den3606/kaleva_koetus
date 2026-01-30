local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local LevelTags = EventDefs.Tags

local a20_boss_died_key = LevelTags.A20 .. EventTypes.BOSS_DIED
local a20_sampo_tag = LevelTags.A20 .. "sampo_to_remove"

local sampo_entity_id = GetUpdatedEntityID()

if GlobalsGetValue(a20_boss_died_key, "0") == "1" or ((tonumber(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT")) or 0) > 0) then
  return
end

EntityAddTag(sampo_entity_id, a20_sampo_tag)
