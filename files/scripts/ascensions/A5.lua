local Logger = KalevaLogger or dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A5")

local SLOT_REDUCTION = 6
local MIN_FULL_SLOTS = 1

ascension.level = 5
ascension.name = "Ascension 5"
ascension.description = "あなたのスロットは -" .. SLOT_REDUCTION .. "減ります。"
ascension.tag_name = AscensionTags.A5 .. "_player"

local function clamp_slots(original_slots)
  local reduced = original_slots - SLOT_REDUCTION
  if reduced < MIN_FULL_SLOTS then
    return MIN_FULL_SLOTS
  end

  return reduced
end

function ascension:on_activate()
  log:info("Spell inventory slot reduction active (-%d)", SLOT_REDUCTION)
end

function ascension:on_player_spawn(player_entity_id)
  if EntityHasTag(player_entity_id, ascension.tag_name) then
    return
  end

  local inventory_component = EntityGetFirstComponent(player_entity_id, "Inventory2Component")
  if not inventory_component then
    log:warn("Player inventory component missing on spawn")
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_x")
  local target_slots = clamp_slots(current_slots)

  if current_slots == target_slots then
    EntityAddTag(player_entity_id, ascension.tag_name)
    return
  end

  ComponentSetValue2(inventory_component, "full_inventory_slots_x", target_slots)
  EntityAddTag(player_entity_id, ascension.tag_name)

  log:debug("Full inventory slots reduced %d -> %d", current_slots, target_slots)
end

return ascension
