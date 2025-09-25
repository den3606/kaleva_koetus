local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A7")

local MATERIAL_SCALE = 0.75
local PROCESS_INTERVAL_FRAMES = 60
local TARGET_TAGS = { "potion", "potion_powder_stash", "powder_stash" }
local PROCESSED_TAG = AscensionTags.A7 .. "processed"

ascension.level = 7
ascension.name = "ポーション量減少"
ascension.description = "ポーションの量が75%に減少"

ascension._last_process_frame = nil

local function scale_inventory(entity_id)
  if EntityHasTag(entity_id, PROCESSED_TAG) then
    return
  end

  local inventory_component = EntityGetFirstComponentIncludingDisabled(entity_id, "MaterialInventoryComponent")
  if not inventory_component then
    return
  end

  local ok_counts, counts = pcall(ComponentGetValue2, inventory_component, "count_per_material_type")
  if not ok_counts then
    log:error("Failed to read material inventory: %s", tostring(counts))
    EntityAddTag(entity_id, PROCESSED_TAG)
    return
  end

  local adjusted = false
  for index, amount in ipairs(counts) do
    if amount ~= 0 then
      counts[index] = amount * MATERIAL_SCALE
      adjusted = true
    end
  end

  if adjusted then
    local ok_set, err = pcall(ComponentSetValue2, inventory_component, "count_per_material_type", counts)
    if not ok_set then
      log:error("Failed to update material inventory: %s", tostring(err))
    else
      log:debug("Scaled potion %d contents to %.0f%%", entity_id, MATERIAL_SCALE * 100)
    end
  end

  EntityAddTag(entity_id, PROCESSED_TAG)
end

local function process_tagged_entities()
  for _, tag in ipairs(TARGET_TAGS) do
    local entity_ids = EntityGetWithTag(tag)
    if entity_ids then
      for _, entity_id in ipairs(entity_ids) do
        scale_inventory(entity_id)
      end
    end
  end
end

function ascension:on_activate()
  log:info("Potion volume reduced to %.0f%%", MATERIAL_SCALE * 100)
end

function ascension:on_player_spawn(_player_entity_id)
  process_tagged_entities()
end

function ascension:on_update()
  local current_frame = GameGetFrameNum()
  if self._last_process_frame and current_frame - self._last_process_frame < PROCESS_INTERVAL_FRAMES then
    return
  end

  process_tagged_entities()
  self._last_process_frame = current_frame
end

return ascension
