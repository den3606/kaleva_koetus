local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local BeyondBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local BeyondTags = EventDefs.BeyondTags
local EventTypes = EventDefs.Types

local beyond = setmetatable({}, { __index = BeyondBase })

local log = Logger:new("b2.lua")

local SALE_TAG = BeyondTags.B2 .. "sale_indicator"
local SHOP_TAG = BeyondTags.B2 .. "shop_item"
local SPELL_PRICE_MULTIPLIER_MIN = 1.5
local SPELL_PRICE_MULTIPLIER_MAX = 3.0
local WAND_PRICE_MULTIPLIER_MIN = 1.5
local WAND_PRICE_MULTIPLIER_MAX = 2.5
local MIN_PRICE_INCREASE = 50

beyond.level = 2
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level
beyond.tag_name = BeyondTags.B2 .. EventTypes.SHOP_CARD_SPAWN .. EventTypes.SHOP_WAND_SPAWN

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

local function increase_prices(entity_ids, x, y, multiplier_min, multiplier_max)
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

  SetRandomSeed(x, y + beyond.level)
  for _, target_entity_id in ipairs(proposal_entity_ids) do
    local multiplier = Randomf(multiplier_min, multiplier_max)
    log:debug("target_entity_id: %d", target_entity_id)
    log:debug("multiplier: %.2f", multiplier)
    update_item_cost(target_entity_id, multiplier)
    EntityAddTag(target_entity_id, beyond.tag_name)
  end
end

function beyond:on_activate()
  -- log:info("Shop price increase active")
  ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/kaleva_koetus/files/scripts/appends/temple_altar.lua")
end

function beyond:on_shop_card_spawn(payload)
  log:debug("on_shop_card_spawn called")
  local entity_ids = payload[1]
  local x = payload[2]
  local y = payload[3]

  increase_prices(entity_ids, x, y, SPELL_PRICE_MULTIPLIER_MIN, SPELL_PRICE_MULTIPLIER_MAX)
end

function beyond:on_shop_wand_spawn(payload)
  log:debug("on_shop_wand_spawn called")
  local entity_ids = payload[1]
  local x = payload[2]
  local y = payload[3]

  increase_prices(entity_ids, x, y, WAND_PRICE_MULTIPLIER_MIN, WAND_PRICE_MULTIPLIER_MAX)
end

return beyond
