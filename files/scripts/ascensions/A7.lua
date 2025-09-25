local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("A7.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
local ascension = setmetatable({}, { __index = AscensionBase })

local MATERIAL_SCALE = 0.5

ascension.level = 7
ascension.name = "ポーション量減少"
ascension.description = "ポーションの量が50%に減少"
ascension.tag_name = AscensionTags.A7 .. EventTypes.POTION_GENERATED

function ascension:on_activate()
  log:info("Potion volume reduced to %.0f%%", MATERIAL_SCALE * 100)
end

function ascension:on_potion_generated(payload)
  log:info("on_potion_generated")
  local potion_entity_id = tonumber(payload[1])
  log:info("potion_entity: " .. potion_entity_id)
  local component_id = EntityGetFirstComponentIncludingDisabled(potion_entity_id, "MaterialSuckerComponent")

  local original_barrel_size = ComponentGetValue2(component_id, "barrel_size")
  local resized_barrel_size = original_barrel_size * MATERIAL_SCALE
  log:info("potion_entity: " .. resized_barrel_size)

  ComponentSetValue2(component_id, "barrel_size", resized_barrel_size)

  local material_id = GetMaterialInventoryMainMaterial(potion_entity_id)
  RemoveMaterialInventoryMaterial(potion_entity_id)
  AddMaterialInventoryMaterial(potion_entity_id, CellFactory_GetName(material_id), resized_barrel_size)

  log:debug("Scaled potion %d contents to %.0f%%", potion_entity_id, resized_barrel_size)

  EntityAddTag(potion_entity_id, ascension.tag_name)
end

return ascension
