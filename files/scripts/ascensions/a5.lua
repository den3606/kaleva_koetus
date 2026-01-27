local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 5
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

local log = Logger:new("a5.lua")

local SLOT_REDUCTION = 6
local MIN_FULL_SLOTS = 1

local a5_player_tag = AscensionTags.A5 .. EventTypes.PLAYER_SPAWN

local function clamp_slots(original_slots)
  local reduced = original_slots - SLOT_REDUCTION
  if reduced < MIN_FULL_SLOTS then
    return MIN_FULL_SLOTS
  end

  return reduced
end

function ascension:on_mod_init()
  log:info("Spell inventory slot reduction active (-%d)", SLOT_REDUCTION)
end

function ascension:on_player_spawned(player_entity_id)
  if EntityHasTag(player_entity_id, a5_player_tag) then
    return
  end

  local inventory_component = EntityGetFirstComponent(player_entity_id, "Inventory2Component")
  if not inventory_component then
    -- log:warn("Player inventory component missing on spawn")
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_x")
  local target_slots = clamp_slots(current_slots)

  if current_slots == target_slots then
    EntityAddTag(player_entity_id, a5_player_tag)
    return
  end

  ComponentSetValue2(inventory_component, "full_inventory_slots_x", target_slots)
  EntityAddTag(player_entity_id, a5_player_tag)

  -- log:debug("Full inventory slots reduced %d -> %d", current_slots, target_slots)
end

return ascension
