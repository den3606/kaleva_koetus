local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a2.lua")

local SALE_TAG = "sale_indicator"
local SPELL_PRICE_MULTIPLIER = 1.35
local WAND_PRICE_MULTIPLIER = 1.75
local MIN_PRICE_INCREASE = 10

ascension.level = 2
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A2 .. EventTypes.SHOP_CARD_SPAWN .. EventTypes.SHOP_WAND_SPAWN

local function is_sale_indicator_near(entity_id)
  if not entity_id then
    return false
  end

  local x, y = EntityGetTransform(entity_id)
  local indicator_id = EntityGetClosestWithTag(x, y, SALE_TAG)
  return not not indicator_id
end

local function round_price(current_price, multiplier)
  local scaled = math.floor(current_price * multiplier + 0.5)
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

  local storages = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
  if storages then
    for _, comp_id in ipairs(storages) do
      local name = ComponentGetValue2(comp_id, "name")
      if name == "shop_cost" or name == "item_cost" or name == "price" then
        local current = ComponentGetValue2(comp_id, "value_int")
        if current and current > 0 then
          local new_value = round_price(current, multiplier)
          ComponentSetValue2(comp_id, "value_int", new_value)
          updated = true
        end
      end
    end
  end

  if updated then
    EntityAddTag(entity_id, ascension.tag_name)
  end

  return updated
end

local function increase_prices(entity_ids, multiplier)
  for _, entity_id in ipairs(entity_ids) do
    local should_skip = false

    if EntityHasTag(entity_id, ascension.tag_name) then
      should_skip = true
    elseif is_sale_indicator_near(entity_id) then
      log:debug("Skipping sale item %d", entity_id)
      should_skip = true
    end

    if not should_skip then
      if update_item_cost(entity_id, multiplier) then
        log:debug("Price increased for entity %d", entity_id)
      else
        log:debug("No cost component found for entity %d", entity_id)
      end
    end
  end
end

function ascension:on_activate()
  log:info("Shop price increase active")
end

function ascension:on_shop_card_spawn(payload)
  local entity_ids = payload[1]
  increase_prices(entity_ids, SPELL_PRICE_MULTIPLIER)
end

function ascension:on_shop_wand_spawn(payload)
  local entity_ids = payload[1]
  increase_prices(entity_ids, WAND_PRICE_MULTIPLIER)
end

return ascension
