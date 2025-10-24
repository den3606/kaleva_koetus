local _ = dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/variable_storage.lua")

local entity_id = GetUpdatedEntityID()
local added_frame = GetInternalVariableValue(entity_id, "added_frame", "value_int")
if added_frame == nil then
  return
end

local game_effect_component = EntityGetFirstComponent(entity_id, "GameEffectComponent")
if game_effect_component == nil then
  return
end

local frames_in_effect = ComponentGetValue2(game_effect_component, "frames")
if frames_in_effect < 2 then
  return
end

local next_perform_frame = tonumber(GlobalsGetValue("kaleva_koetus_next_fungal_shift_perform_frame")) or -1
local now_frame = GameGetFrameNum()
local frames_left = math.max(next_perform_frame - now_frame, 1)

ComponentSetValue2(game_effect_component, "frames", frames_left)
