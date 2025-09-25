local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A15")

local MAX_WANDS = 3

ascension.level = 15
ascension.name = "杖枠減少"
ascension.description = "持てる杖の数が1つ減少する"

local function get_quick_inventory(player_entity_id)
  local children = EntityGetAllChildren(player_entity_id)
  if not children then
    return nil
  end

  for _, child in ipairs(children) do
    if EntityGetName(child) == "inventory_quick" then
      return child
    end
  end

  return nil
end

local function clamp_quick_inventory_slots(player_entity_id)
  local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
  if not inventory_component then
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_y") or 1
  if current_slots > MAX_WANDS - 1 then
    ComponentSetValue2(inventory_component, "full_inventory_slots_y", math.max(0, MAX_WANDS - 1))
  end
end

local function enforce_wand_limit()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  clamp_quick_inventory_slots(player_entity_id)

  local inventory_quick = get_quick_inventory(player_entity_id)
  if not inventory_quick then
    return
  end

  local items = EntityGetAllChildren(inventory_quick) or {}
  local wand_ids = {}
  for _, item_id in ipairs(items) do
    if EntityHasTag(item_id, "wand") then
      wand_ids[#wand_ids + 1] = item_id
    end
  end

  if #wand_ids <= MAX_WANDS then
    return
  end

  local px, py = EntityGetTransform(player_entity_id)
  SetRandomSeed(px + GameGetFrameNum(), py)

  local dropped_any = false
  for index = MAX_WANDS + 1, #wand_ids do
    local wand_id = wand_ids[index]
    EntityRemoveFromParent(wand_id)
    EntitySetTransform(wand_id, px + Random(-12, 12), py - 4)
    dropped_any = true
  end

  if dropped_any then
    GamePrint("You can only juggle three wands now!")
    log:debug("Excess wands dropped to the ground")
  end
end

function ascension:on_activate()
  log:info("Limiting wand slots to %d", MAX_WANDS)
end

function ascension:on_player_spawn(_player_entity_id)
  enforce_wand_limit()
end

function ascension:on_update()
  enforce_wand_limit()
end

return ascension
