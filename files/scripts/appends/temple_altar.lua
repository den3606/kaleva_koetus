local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
local EventTypes = EventDefs.Types
local EventBroker = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_broker.lua")

local _spawn_all_shopitems = spawn_all_shopitems

---@param ids EntityIdList
---@return table<EntityId, boolean>
local function to_lookup(ids)
  local lookup = {}
  for _, entity_id in ipairs(ids) do
    lookup[entity_id] = true
  end
  return lookup
end

---@param before EntityIdList
---@param after EntityIdList
---@return EntityIdList
local function diff_entities(before, after)
  if #after == 0 then
    return {}
  end

  if #before == 0 then
    return after
  end

  local before_lookup = to_lookup(before)
  local new_entities = {}

  for _, entity_id in ipairs(after) do
    if not before_lookup[entity_id] then
      new_entities[#new_entities + 1] = entity_id
    end
  end

  return new_entities
end

---@param tag string
---@return EntityIdList
local function get_entities_with_tag(tag)
  local ids = EntityGetWithTag(tag)
  if not ids then
    return {}
  end

  local result = {}
  for _, entity_id in ipairs(ids) do
    local numeric_id = tonumber(entity_id)
    if numeric_id then
      result[#result + 1] = numeric_id
    end
  end

  return result
end

---@param x number
---@param y number
-- selene: allow(unused_variable)
function spawn_all_shopitems(x, y)
  local before_card_entity_ids = get_entities_with_tag("card_action")
  local before_wand_entity_ids = get_entities_with_tag("wand")

  _spawn_all_shopitems(x, y)

  local after_card_entity_ids = get_entities_with_tag("card_action")
  local after_wand_entity_ids = get_entities_with_tag("wand")

  local shop_card_entity_ids = diff_entities(before_card_entity_ids, after_card_entity_ids)
  local shop_wand_entity_ids = diff_entities(before_wand_entity_ids, after_wand_entity_ids)

  if #shop_card_entity_ids ~= 0 then
    EventBroker:publish_event_async("temple_altar", EventTypes.SHOP_CARD_SPAWN, shop_card_entity_ids, x, y)
  end

  if #shop_wand_entity_ids ~= 0 then
    EventBroker:publish_event_async("temple_altar", EventTypes.SHOP_WAND_SPAWN, shop_wand_entity_ids, x, y)
  end
end
