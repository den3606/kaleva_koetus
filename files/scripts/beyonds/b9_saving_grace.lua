---@type PerkUtils
local PerkUtils = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_perk_utils.lua")
local get_tagged_game_effect_count = PerkUtils.get_tagged_game_effect_count
local get_perk_pickup_count = PerkUtils.get_perk_pickup_count

-- selene: allow(unused_variable)
function damage_received(_damage, _message, _entity_thats_responsible, is_fatal, _projectile_thats_responsible)
  if is_fatal ~= true then
    return
  end

  local entity_id = GetUpdatedEntityID()

  local saving_grace_count = GameGetGameEffectCount(entity_id, "SAVING_GRACE")
  if saving_grace_count == 0 then
    return
  end

  local perk_effect_entity_count = get_tagged_game_effect_count(entity_id, "SAVING_GRACE", "kaleva_koetus_saving_grace_effect")
  if perk_effect_entity_count < saving_grace_count then
    return
  end

  local perk_pickup_count = get_perk_pickup_count(entity_id, "SAVING_GRACE")
  if perk_pickup_count >= 2 then
    return
  end

  local script_path = "mods/kaleva_koetus/files/scripts/beyonds/b9_saving_grace_disable.lua"

  local lua_components = EntityGetComponent(entity_id, "LuaComponent")
  if lua_components ~= nil then
    for _, lua_component_id in ipairs(lua_components) do
      local script_source_file = ComponentGetValue2(lua_component_id, "script_source_file")
      if script_source_file == script_path then
        return
      end
    end
  end

  local _ = EntityAddComponent2(entity_id, "LuaComponent", {
    script_source_file = script_path,
    execute_every_n_frame = 0,
    remove_after_executed = true,
  })
end
