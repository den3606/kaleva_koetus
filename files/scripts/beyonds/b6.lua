local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local LevelTags = EventDefs.Tags
local EventTypes = EventDefs.Types

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 6
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

local log = Logger:new("b6.lua")

local LEVITATION_SCALE = 0.7
local VERTICAL_SPEED_MULTIPLIER = 0.7

local b6_player_tag = LevelTags.B6 .. EventTypes.PLAYER_SPAWN

local function scale_levitation(player_entity_id, reset)
  if not reset and EntityHasTag(player_entity_id, b6_player_tag) then
    return
  end

  local character_data_component = EntityGetFirstComponent(player_entity_id, "CharacterDataComponent")
  if character_data_component ~= nil then
    local current_max = reset and 3 or ComponentGetValue2(character_data_component, "fly_time_max")

    local new_max = current_max * LEVITATION_SCALE
    ComponentSetValue2(character_data_component, "fly_time_max", new_max)
  else
    log:warn("CharacterDataComponent not found on player")
  end

  local character_platforming_component = EntityGetFirstComponent(player_entity_id, "CharacterPlatformingComponent")
  if character_platforming_component ~= nil then
    local jump_velocity_y = reset and -95 or ComponentGetValue2(character_platforming_component, "jump_velocity_y")
    local fly_speed_change_spd = reset and 0.25 or ComponentGetValue2(character_platforming_component, "fly_speed_change_spd")
    local pixel_gravity = reset and 350 or ComponentGetValue2(character_platforming_component, "pixel_gravity")

    local target = pixel_gravity / fly_speed_change_spd - 5700
    target = target * VERTICAL_SPEED_MULTIPLIER

    jump_velocity_y = jump_velocity_y * VERTICAL_SPEED_MULTIPLIER
    pixel_gravity = pixel_gravity * VERTICAL_SPEED_MULTIPLIER
    fly_speed_change_spd = pixel_gravity / (target + 5700)

    ComponentSetValue2(character_platforming_component, "jump_velocity_y", jump_velocity_y)
    ComponentSetValue2(character_platforming_component, "fly_speed_change_spd", fly_speed_change_spd)
    ComponentSetValue2(character_platforming_component, "pixel_gravity", pixel_gravity)
  else
    log:warn("CharacterPlatformingComponent not found on player")
  end

  EntityAddTag(player_entity_id, b6_player_tag)
end

function beyond:on_mod_init()
  -- log:info("Levitation reduced to %.0f%%", LEVITATION_SCALE * 100)
end

function beyond:on_player_spawned(player_entity_id)
  scale_levitation(player_entity_id, false)
end

function beyond:on_perk_remove_all(player_entity_id)
  scale_levitation(player_entity_id, true)
end

return beyond
