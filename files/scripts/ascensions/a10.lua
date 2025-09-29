local _ = dofile_once("data/scripts/lib/coroutines.lua")
local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a10.lua")

local WAIT_FRAME = 60 * 60 * 15
local DELAY_FRAME = 60 * 2

ascension.level = 10
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A10 .. EventTypes.PLAYER_SPAWN

ascension._next_process_frame = nil

local function start_fungal_shift(player_entity_id)
  GlobalsSetValue("fungal_shift_last_frame", "-1000000")
  EntityAddChild(player_entity_id, EntityLoad("data/entities/misc/effect_trip_00.xml"))
  EntityAddChild(player_entity_id, EntityLoad("data/entities/misc/effect_trip_01.xml"))
  EntityAddChild(player_entity_id, EntityLoad("data/entities/misc/effect_trip_02.xml"))
  EntityAddChild(player_entity_id, EntityLoad("data/entities/misc/effect_trip_03.xml"))
end

function ascension:on_activate()
  log:info("fungal shift enabled")
end

function ascension:on_player_spawn(player_entity_id)
  async(function()
    wait(DELAY_FRAME)
    start_fungal_shift(player_entity_id)
  end)

  EntityAddTag(player_entity_id, self.tag_name)
end

function ascension:on_fungal_shifted()
  local player_entity_id = GetPlayerEntity()
  local x, y = EntityGetTransform(player_entity_id)
  local effect_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/effect_fungal_shift_curse.xml", x, y)
  local game_effect_component_id = EntityGetFirstComponentIncludingDisabled(effect_id, "GameEffectComponent")
  ComponentSetValue2(game_effect_component_id, "frames", WAIT_FRAME)

  local _ = EntityAddComponent2(effect_id, "LifetimeComponent", {
    lifetime = WAIT_FRAME,
  })
  EntityAddChild(player_entity_id, effect_id)
  GamePrintImportant("$kaleva_koetus_fungal_shift_curse_again", "$kaleva_koetus_fungal_shift_curse_again_description")
end

function ascension:on_fungal_shift_curse_released()
  local player_entity_id = GetPlayerEntity()
  if player_entity_id then
    start_fungal_shift(player_entity_id)
  end
end

return ascension
