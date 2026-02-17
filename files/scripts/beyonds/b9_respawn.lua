---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_add_variable_storage = VariableUtils.entity_add_variable_storage

---@type PerkUtils
local PerkUtils = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_perk_utils.lua")
local get_game_effect_components = PerkUtils.get_game_effect_components

---@module "ReserveRespawnIcons"
local reserve_all_respawn_icons = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_reserve.lua")

-- selene: allow(unused_variable)
function damage_received(_damage, _message, _entity_thats_responsible, is_fatal, _projectile_thats_responsible)
  if is_fatal ~= true then
    return
  end

  local entity_id = GetUpdatedEntityID()

  local saving_grace_count = GameGetGameEffectCount(entity_id, "SAVING_GRACE")
  if saving_grace_count > 0 then
    local damage_model_component_id = EntityGetFirstComponent(entity_id, "DamageModelComponent")
    if damage_model_component_id == nil then
      return
    end

    local hp = ComponentGetValue2(damage_model_component_id, "hp")
    if hp > 0.04 then
      return
    end
  end

  local respawn_component_id

  local respawn_effect_components = get_game_effect_components(entity_id, "RESPAWN")
  for _, effect_component_id in ipairs(respawn_effect_components) do
    local mCounter = ComponentGetValue2(effect_component_id, "mCounter")
    if mCounter == 0 then
      respawn_component_id = effect_component_id
      break
    end
  end

  if respawn_component_id == nil then
    return
  end

  local respawn_entity_id = ComponentGetEntity(respawn_component_id)
  if entity_has_variable_tag(respawn_entity_id, "kaleva_koetus_respawn_effect") == false then
    return
  end

  local frame_storage_component_id = entity_add_variable_storage(entity_id, "kaleva_koetus_respawn_frame")
  local last_respawn_frame = ComponentGetValue2(frame_storage_component_id, "value_int")

  local now_frame = GameGetFrameNum()
  if last_respawn_frame == now_frame then
    return
  end
  ComponentSetValue2(frame_storage_component_id, "value_int", now_frame)

  local no_heal_entity_id = EntityCreateNew()
  local _ = EntityAddComponent2(no_heal_entity_id, "GameEffectComponent", {
    frames = 1,
    effect = "NO_HEAL",
    no_heal_max_hp_cap = 0.04,
  })
  EntityAddChild(entity_id, no_heal_entity_id)

  local mIsSpent = ComponentGetValue2(respawn_component_id, "mIsSpent")
  if mIsSpent == true then
    return
  end

  reserve_all_respawn_icons(entity_id)
end
