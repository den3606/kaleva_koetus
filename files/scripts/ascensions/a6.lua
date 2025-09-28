local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a6.lua")

local LEVITATION_SCALE = 0.7

ascension.level = 6
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A6 .. EventTypes.PLAYER_SPAWN

local function scale_levitation(player_entity_id)
  if EntityHasTag(player_entity_id, ascension.tag_name) then
    return
  end

  local character_data_component = EntityGetFirstComponent(player_entity_id, "CharacterDataComponent")
  if not character_data_component then
    log:warn("CharacterDataComponent not found on player")
    return
  end

  local current_max = ComponentGetValue2(character_data_component, "fly_time_max")
  if not current_max then
    log:error("Failed to read fly_time_max: %s", tostring(current_max))
    return
  end

  local new_max = current_max * LEVITATION_SCALE
  ComponentSetValue2(character_data_component, "fly_time_max", new_max)

  EntityAddTag(player_entity_id, ascension.tag_name)

  log:debug("Levitation capacity scaled %.2f -> %.2f", current_max, new_max)
end

function ascension:on_activate()
  log:info("Levitation reduced to %.0f%%", LEVITATION_SCALE * 100)
end

function ascension:on_player_spawn(player_entity_id)
  scale_levitation(player_entity_id)
end

return ascension
