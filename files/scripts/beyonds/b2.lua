-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local LevelTags = EventDefs.Tags
local EventTypes = EventDefs.Types

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 2
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

-- local log = Logger:new("b2.lua")

local SHOP_TAG = LevelTags.B2 .. "shop_item"
local SPELL_PRICE_MULTIPLIER_MIN = 1.5
local SPELL_PRICE_MULTIPLIER_MAX = 3.0
local WAND_PRICE_MULTIPLIER_MIN = 1.5
local WAND_PRICE_MULTIPLIER_MAX = 2.5
local MIN_PRICE_INCREASE = 50

local b2_reroll_key = LevelTags.B2 .. "increase_reroll_count"

local b2_shop_item_tag = LevelTags.B2 .. EventTypes.SHOP_CARD_SPAWN .. EventTypes.SHOP_WAND_SPAWN

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

  SetRandomSeed(x, y + beyond.level)
  for _, entity_id in ipairs(entity_ids) do
    local multiplier = Randomf(multiplier_min, multiplier_max)
    -- log:debug("entity_id: %d", entity_id)
    -- log:debug("multiplier: %.2f", multiplier)
    update_item_cost(entity_id, multiplier)
    EntityAddTag(entity_id, b2_shop_item_tag)
  end
end

function beyond:on_mod_init()
  -- log:info("Shop price increase active")
  ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/kaleva_koetus/files/scripts/appends/temple_altar_b2.lua")
  ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/temple_altar_b2.lua")
end

function beyond:on_world_initialized()
  if GlobalsGetValue(b2_reroll_key, "0") == "1" then
    return
  end

  local perk_reroll_count = tonumber(GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT")) or 0
  perk_reroll_count = perk_reroll_count + 2
  GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", tostring(perk_reroll_count))

  GlobalsSetValue(b2_reroll_key, "1")
end

function beyond:on_shop_card_spawn(entity_ids, x, y)
  increase_prices(entity_ids, x, y, SPELL_PRICE_MULTIPLIER_MIN, SPELL_PRICE_MULTIPLIER_MAX)
end

function beyond:on_shop_wand_spawn(entity_ids, x, y)
  increase_prices(entity_ids, x, y, WAND_PRICE_MULTIPLIER_MIN, WAND_PRICE_MULTIPLIER_MAX)
end

return beyond
