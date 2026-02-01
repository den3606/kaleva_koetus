local EventRemote = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_remote.lua")

local _spawn_all_shopitems = spawn_all_shopitems

local function get_shop_card_entities()
  local entity_ids = EntityGetWithTag("card_action")
  local shop_entity_ids = {}

  for _, entity_id in ipairs(entity_ids) do
    local is_shop_entity = not not EntityGetFirstComponent(entity_id, "ItemCostComponent", "shop_cost")
    if is_shop_entity then
      table.insert(shop_entity_ids, entity_id)
    end
  end

  return shop_entity_ids
end

local function get_shop_wand_entities()
  local entity_ids = EntityGetWithTag("wand")
  local shop_entity_ids = {}

  for _, entity_id in ipairs(entity_ids) do
    local is_shop_entity = not not EntityGetFirstComponent(entity_id, "ItemCostComponent", "shop_cost")
    if is_shop_entity then
      table.insert(shop_entity_ids, entity_id)
    end
  end

  return shop_entity_ids
end

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

-- selene: allow(unused_variable)
function spawn_all_shopitems(x, y)
  local before_card_entity_ids = get_shop_card_entities()
  local before_wand_entity_ids = get_shop_wand_entities()

  _spawn_all_shopitems(x, y)

  local after_card_entity_ids = get_shop_card_entities()
  local after_wand_entity_ids = get_shop_wand_entities()

  local shop_card_entity_ids = diff_entities(before_card_entity_ids, after_card_entity_ids)
  local shop_wand_entity_ids = diff_entities(before_wand_entity_ids, after_wand_entity_ids)

  if #shop_card_entity_ids ~= 0 then
    EventRemote.SHOP_CARD_SPAWN(shop_card_entity_ids, x, y)
  end

  if #shop_wand_entity_ids ~= 0 then
    EventRemote.SHOP_WAND_SPAWN(shop_wand_entity_ids, x, y)
  end
end
