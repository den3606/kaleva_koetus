local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local SLOT_REDUCTION = 6
local MIN_FULL_SLOTS = 1

ascension.level = 5
ascension.name = "Ascension 5"
ascension.description = "Reduces the player's spell inventory slots by " .. SLOT_REDUCTION .. "."

local function clamp_slots(original_slots)
  local reduced = original_slots - SLOT_REDUCTION
  if reduced < MIN_FULL_SLOTS then
    return MIN_FULL_SLOTS
  end

  return reduced
end

function ascension:on_activate()
  print("[Kaleva Koetus A5] Spell inventory slot reduction active (-3)")
end

function ascension:on_player_spawn(player_entity_id)
  print("[Kaleva Koetus A5] on_player_spawn")
  local inventory_component = EntityGetFirstComponent(player_entity_id, "Inventory2Component")
  if inventory_component == nil then
    print("[Kaleva Koetus A5] Player inventory component missing on spawn")
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_x")
  local target_slots = clamp_slots(current_slots)

  if current_slots == target_slots then
    return
  end

  ComponentSetValue2(inventory_component, "full_inventory_slots_x", target_slots)

  print(string.format("[Kaleva Koetus A5] Player full inventory slots reduced: %d -> %d", current_slots, target_slots))
end

return ascension
