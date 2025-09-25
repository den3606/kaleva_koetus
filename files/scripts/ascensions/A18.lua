local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("A18")

local MAX_ITEMS = 1

ascension.level = 18
ascension.name = "アイテム枠減少"
ascension.description = "手持ちアイテム枠が1つ減少する"
ascension.tag_name = AscensionTags.A18 .. "_limited"

local function get_inventory_full(player_entity_id)
  local children = EntityGetAllChildren(player_entity_id)
  if not children then
    return nil
  end

  for _, child in ipairs(children) do
    if EntityGetName(child) == "inventory_full" then
      return child
    end
  end

  return nil
end

local function clamp_inventory_component(player_entity_id)
  local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
  if not inventory_component then
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_x") or 16
  if current_slots > MAX_ITEMS then
    ComponentSetValue2(inventory_component, "full_inventory_slots_x", math.max(1, MAX_ITEMS))
  end
end

local function enforce_item_limit()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  clamp_inventory_component(player_entity_id)

  local inventory_full = get_inventory_full(player_entity_id)
  if not inventory_full then
    return
  end

  local items = EntityGetAllChildren(inventory_full) or {}
  if #items <= MAX_ITEMS then
    return
  end

  local px, py = EntityGetTransform(player_entity_id)
  SetRandomSeed(px + GameGetFrameNum(), py - 17)

  local dropped = false
  for index = MAX_ITEMS + 1, #items do
    local item_id = items[index]
    EntityRemoveFromParent(item_id)
    EntitySetTransform(item_id, px + Random(-10, 10), py - 6)
    dropped = true
  end

  if dropped then
    GamePrint("Your pack feels cramped. Excess items spill out!")
    log:debug("Dropped %d excess items", #items - MAX_ITEMS)
  end

  EntityAddTag(player_entity_id, ascension.tag_name)
end

function ascension:on_activate()
  log:info("Item slots limited to %d", MAX_ITEMS)
end

function ascension:on_player_spawn(_player_entity_id)
  enforce_item_limit()
end

function ascension:on_update()
  enforce_item_limit()
end

return ascension
