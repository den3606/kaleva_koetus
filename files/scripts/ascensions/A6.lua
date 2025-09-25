local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A6")

local LEVITATION_SCALE = 0.75

ascension.level = 6
ascension.name = "上昇力減少"
ascension.description = "上昇ゲージが75%になる"

local function scale_levitation(player_entity_id)
  local processed_tag = AscensionTags.A6 .. "player"
  if EntityHasTag(player_entity_id, processed_tag) then
    return
  end

  local character_data_component = EntityGetFirstComponent(player_entity_id, "CharacterDataComponent")
  if not character_data_component then
    log:warn("CharacterDataComponent not found on player")
    return
  end

  local ok_max, current_max = pcall(ComponentGetValue2, character_data_component, "fly_time_max")
  if not ok_max then
    log:error("Failed to read fly_time_max: %s", tostring(current_max))
    return
  end

  local new_max = current_max * LEVITATION_SCALE
  ComponentSetValue2(character_data_component, "fly_time_max", new_max)

  local ok_current, current_time = pcall(ComponentGetValue2, character_data_component, "fly_time")
  if ok_current and current_time > new_max then
    ComponentSetValue2(character_data_component, "fly_time", new_max)
  end

  EntityAddTag(player_entity_id, processed_tag)

  log:debug("Levitation capacity scaled %.2f -> %.2f", current_max, new_max)
end

function ascension:on_activate()
  log:info("Levitation reduced to %.0f%%", LEVITATION_SCALE * 100)
end

function ascension:on_player_spawn(player_entity_id)
  scale_levitation(player_entity_id)
end

return ascension
