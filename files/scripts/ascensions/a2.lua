-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a2.lua")

local SALE_TAG = AscensionTags.A2 .. "sale_indicator"
local SHOP_TAG = AscensionTags.A2 .. "shop_item"
local SPELL_PRICE_MULTIPLIER = 2.2
local WAND_PRICE_MULTIPLIER = 1.5
local MIN_PRICE_INCREASE = 50

ascension.level = 2
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A2 .. EventTypes.SHOP_CARD_SPAWN .. EventTypes.SHOP_WAND_SPAWN

local function pick_random(ids, pick_count, seed_a, seed_b)
  local picked_entity_ids = {}
  if type(ids) ~= "table" or #ids < pick_count then
    return {}
  end

  local copy = {}
  for i = 1, #ids do
    copy[i] = ids[i]
  end

  SetRandomSeed(seed_a, seed_b)
  for i = 1, #copy, 1 do
    local j = Random(1, i)
    copy[i], copy[j] = copy[j], copy[i]
  end

  for i, entity_id in ipairs(copy) do
    if i <= pick_count then
      table.insert(picked_entity_ids, entity_id)
    end
  end

  return picked_entity_ids
end

local function round_price(current_price, multiplier)
  local scaled = math.floor(current_price * multiplier)
  local minimum = current_price + MIN_PRICE_INCREASE

  if scaled < minimum then
    scaled = minimum
  end
  return scaled
end

local function update_item_cost(entity_id, multiplier)
  local updated = false

  local cost_components = EntityGetComponentIncludingDisabled(entity_id, "ItemCostComponent")
  if cost_components then
    for _, comp_id in ipairs(cost_components) do
      local current_cost = ComponentGetValue2(comp_id, "cost")
      if current_cost and current_cost > 0 then
        local new_cost = round_price(current_cost, multiplier)
        ComponentSetValue2(comp_id, "cost", new_cost)
        updated = true
      end
    end
  end

  return updated
end

local function increase_prices(entity_ids, x, y, target_count, multiplier)
  for _, entity_id in ipairs(entity_ids) do
    EntityAddTag(entity_id, SHOP_TAG)
  end

  local sale_tag_entity_id = EntityGetClosestWithTag(x, y, SALE_TAG)
  -- log:debug("sale_tag_entity_id: %d", sale_tag_entity_id)
  local sale_tag_x, sale_tag_y = EntityGetTransform(sale_tag_entity_id)
  local shop_sale_entity_id = EntityGetClosestWithTag(sale_tag_x, sale_tag_y, SHOP_TAG)
  -- log:debug("shop_sale_entity_id: %d", shop_sale_entity_id)

  local proposal_entity_ids = {}
  for _, entity_id in ipairs(entity_ids) do
    if not (entity_id == shop_sale_entity_id) then
      table.insert(proposal_entity_ids, entity_id)
      -- log:debug("proposal_entity_id: %d", entity_id)
    end
  end

  local target_entity_ids = pick_random(proposal_entity_ids, target_count, x, y)

  for _, target_entity_id in ipairs(target_entity_ids) do
    -- log:debug("target_entity_id: %d", target_entity_id)
    update_item_cost(target_entity_id, multiplier)
    EntityAddTag(target_entity_id, ascension.tag_name)
  end
end

function ascension:on_activate()
  -- log:info("Shop price increase active")
end

function ascension:on_shop_card_spawn(payload)
  local entity_ids = payload[1]
  local x = payload[2]
  local y = payload[3]

  increase_prices(entity_ids, x, y, 4, SPELL_PRICE_MULTIPLIER)
end

function ascension:on_shop_wand_spawn(payload)
  local entity_ids = payload[1]
  local x = payload[2]
  local y = payload[3]

  increase_prices(entity_ids, x, y, 2, WAND_PRICE_MULTIPLIER)
end

return ascension
