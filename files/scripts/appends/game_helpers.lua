local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("game_helpers.lua")

local _load_gold_entity = load_gold_entity
-- selene: allow(unused_variable)
function load_gold_entity(entity_filename, x, y, remove_timer)
  local gold_entity_id = _load_gold_entity(entity_filename, x, y, remove_timer)

  log:debug("Gold generate detected")
  EventBroker:publish_event_sync("game_helpers.load_gold_entity", EventTypes.GOLD_SPAWN, gold_entity_id, x, y, remove_timer)

  return gold_entity_id
end
