local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local LevelTags = EventDefs.Tags
local EventTypes = EventDefs.Types

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 5
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

local log = Logger:new("b5.lua")

local SLOT_REDUCTION = 10
local MIN_FULL_SLOTS = 1

local b5_player_tag = LevelTags.B5 .. EventTypes.PLAYER_SPAWN

local function clamp_slots(original_slots)
  local reduced = original_slots - SLOT_REDUCTION
  if reduced < MIN_FULL_SLOTS then
    return MIN_FULL_SLOTS
  end

  return reduced
end

function beyond:on_mod_init()
  log:info("Spell inventory slot reduction active (-%d)", SLOT_REDUCTION)

  ImageEditor:override_image("data/ui_gfx/inventory/background.png", "mods/kaleva_koetus/files/ui_gfx/inventory/b5_background.png")
end

function beyond:on_player_spawned(player_entity_id)
  if EntityHasTag(player_entity_id, b5_player_tag) then
    return
  end

  local inventory_component = EntityGetFirstComponent(player_entity_id, "Inventory2Component")
  if not inventory_component then
    -- log:warn("Player inventory component missing on spawn")
    return
  end

  local current_slots = ComponentGetValue2(inventory_component, "full_inventory_slots_x")
  local target_slots = clamp_slots(current_slots)

  ComponentSetValue2(inventory_component, "full_inventory_slots_x", target_slots)
  EntityAddTag(player_entity_id, b5_player_tag)

  local x, y = EntityGetTransform(player_entity_id)
  for slot_x = 2, 3 do
    local dead_item = EntityLoad("mods/kaleva_koetus/files/entities/pickup/dead_item.xml", x, y)
    local item_component_id = EntityGetFirstComponentIncludingDisabled(dead_item, "ItemComponent")
    if item_component_id ~= nil then
      ComponentSetValue2(item_component_id, "inventory_slot", slot_x, 0)
      GamePickUpInventoryItem(player_entity_id, dead_item)
    end
  end
end

return beyond
