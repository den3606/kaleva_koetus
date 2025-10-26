local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utilities.lua")
_ = dofile_once("data/scripts/magic/fungal_shift.lua")

-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/difficulty_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a10.lua")

local WAIT_FRAME = 60 * 60 * 15
local EFFECT_FRAME = 60 * 10

ascension.level = 10
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A10 .. EventTypes.PLAYER_SPAWN

ascension._next_process_frame = nil

local fungal_effect_tag = "kaleva_koetus_fungal_effect"
local function start_fungal_shift(player_entity_id)
  local fungal_effect_entities = EntityGetAllChildren(player_entity_id, fungal_effect_tag)
  if fungal_effect_entities == nil or #fungal_effect_entities == 0 then
    local x, y = EntityGetTransform(player_entity_id)
    local effect_entity_id = EntityLoad("data/entities/misc/effect_trip_00.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("data/entities/misc/effect_trip_01.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("data/entities/misc/effect_trip_02.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
    effect_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/effect_trip_03_fake.xml", x, y)
    EntityAddTag(effect_entity_id, fungal_effect_tag)
    EntityAddChild(player_entity_id, effect_entity_id)
  end
end

local function clear_fungal_effects(player_entity_id)
  local fungal_effect_entities = EntityGetAllChildren(player_entity_id, fungal_effect_tag)
  if fungal_effect_entities ~= nil then
    for _, fungal_effect_id in ipairs(fungal_effect_entities) do
      EntityKill(fungal_effect_id)
    end
  end
end

local function perform_fungal_shift(player_entity_id)
  local iter_str = GlobalsGetValue("fungal_shift_iteration", "0")
  local last_frame_str = GlobalsGetValue("fungal_shift_last_frame", "-1000000")
  GlobalsSetValue(
    "fungal_shift_iteration",
    tostring(0xA10 + (tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_start_frame")) or 0))
  )
  GlobalsSetValue("fungal_shift_last_frame", "-1000000")

  -- mostly from data/scripts/status_effects/effect_trip_03.lua
  -- selene: allow(undefined_variable)
  local rand = rand
  local pos_x, pos_y = EntityGetTransform(player_entity_id)
  SetRandomSeed(pos_x + GameGetFrameNum(), pos_y)
  if rand(0, 1) > 0.5 then
    local function spawn(x, y)
      _ = EntityLoad("data/entities/particles/treble_eye.xml", x, y)
    end

    local x, y = pos_x + rand(-100, 100), pos_y + rand(-80, 80)
    local rad = rand(0, 30)

    spawn(x, y)
    spawn(x + 40 + rad, y + 30 + rad)
    spawn(x - 40 - rad, y + 30 + rad)
  end
  fungal_shift(player_entity_id, pos_x, pos_y, true)

  GlobalsSetValue("fungal_shift_iteration", iter_str)
  GlobalsSetValue("fungal_shift_last_frame", last_frame_str)
end

local fungal_curse_tag = "kaleva_koetus_fungal_curse"
local function add_fungal_curse(player_entity_id, clean_old)
  local fungal_curse_entities = EntityGetAllChildren(player_entity_id, fungal_curse_tag)
  if fungal_curse_entities ~= nil then
    if clean_old == true then
      for _, fungal_curse_entity_id in ipairs(fungal_curse_entities) do
        EntityKill(fungal_curse_entity_id)
      end
    elseif #fungal_curse_entities > 0 then
      return
    end
  end
  local curse_effect_id = EntityCreateNew()
  local x, y = EntityGetTransform(player_entity_id)
  EntitySetTransform(curse_effect_id, x, y)
  AddNewInternalVariable(curse_effect_id, "added_frame", "value_int", GameGetFrameNum())
  EntityLoadToEntity("mods/kaleva_koetus/files/entities/misc/effect_fungal_shift_curse.xml", curse_effect_id)
  EntityAddTag(curse_effect_id, fungal_curse_tag)
  EntityAddChild(player_entity_id, curse_effect_id)
end

function ascension:on_activate()
  -- log:info("fungal shift enabled")
end

function ascension:on_update()
  local player_entity_id = GetPlayerEntity()
  if player_entity_id == nil or EntityGetIsAlive(player_entity_id) == false then
    return
  end

  local refresh_fungal_curse = false
  local next_start_frame = tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_start_frame")) or 0
  local next_perform_frame = tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_perform_frame")) or -1
  local next_perform_determined = GlobalsGetValue("kaleva_koetus_next_fungal_shift_perform_determined", "0")
  local now_frame = GameGetFrameNum()
  if now_frame >= next_start_frame then
    if next_perform_determined == "0" then
      GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_frame", tostring(now_frame + EFFECT_FRAME))
      GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_determined", "1")
      refresh_fungal_curse = true
      start_fungal_shift(player_entity_id)
    else
      if now_frame >= next_perform_frame then
        perform_fungal_shift(player_entity_id)
        next_start_frame = next_start_frame + WAIT_FRAME
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_start_frame", tostring(next_start_frame))
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_frame", tostring(next_start_frame + EFFECT_FRAME))
        GlobalsSetValue("kaleva_koetus_next_fungal_shift_perform_determined", "0")
        refresh_fungal_curse = true
        GamePrintImportant("$kaleva_koetus_fungal_shift_curse_again", "$kaleva_koetus_fungal_shift_curse_again_description")
        return
      else
        start_fungal_shift(player_entity_id)
      end
    end
  else
    clear_fungal_effects(player_entity_id)
  end

  if next_start_frame > 0 and EntityHasTag(player_entity_id, "player_unit") then
    add_fungal_curse(player_entity_id, refresh_fungal_curse)
  end
end

return ascension
