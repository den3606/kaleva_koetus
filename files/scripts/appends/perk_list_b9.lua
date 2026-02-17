---@type path32
local path32 = dofile_once("mods/kaleva_koetus/files/scripts/lib/path32.lua")

---@type VariableUtils
local VariableUtils = dofile_once("mods/kaleva_koetus/files/scripts/lib/variable_utils.lua")
local entity_has_variable_tag = VariableUtils.entity_has_variable_tag
local entity_add_variable_tag = VariableUtils.entity_add_variable_tag
local entity_remove_variable_tag = VariableUtils.entity_remove_variable_tag
local entity_add_variable_storage = VariableUtils.entity_add_variable_storage

---@type PerkUtils
local PerkUtils = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_perk_utils.lua")
local add_perk_pickup_count = PerkUtils.add_perk_pickup_count
local reset_perk_pickup_count = PerkUtils.reset_perk_pickup_count
local DEFAULT_MAX_STACKABLE_PERK_COUNT = PerkUtils.DEFAULT_MAX_STACKABLE_PERK_COUNT

---@type {max_id_before_pickup:number, post_pickup:fun(post_pickup_func:function), [any]:any}
local vm_global = dofile_once("mods/kaleva_koetus/files/scripts/vm_global.lua")

---@type RespawnIcon
local RespawnIcon = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_icon.lua")

---@module "ReserveRespawnIcons"
local reserve_all_respawn_icons = dofile_once("mods/kaleva_koetus/files/scripts/beyonds/b9_respawn_reserve.lua")

---@param perk_data PerkData
local function enable_stackable(perk_data)
  if perk_data.stackable == false then
    perk_data.stackable = true
    perk_data.stackable_maximum = perk_data.stackable_maximum or 1
    perk_data.max_in_perk_pool = perk_data.max_in_perk_pool or 1
  end
end

---@param perk_data PerkData
---@param maximum number
local function ensure_stackable_maximum(perk_data, maximum)
  local current_maximum = perk_data.stackable_maximum or DEFAULT_MAX_STACKABLE_PERK_COUNT
  if maximum > current_maximum then
    perk_data.stackable_maximum = current_maximum
  end
end

---@param perk_data PerkData
---@param include_ui_icon boolean? true
local function use_modified_info(perk_data, include_ui_icon)
  include_ui_icon = include_ui_icon or true

  local encoded_perk_id = path32.encode(perk_data.id)

  perk_data.ui_name = "$kaleva_koetus_perk_" .. perk_data.id
  perk_data.ui_description = "$kaleva_koetus_perkdesc_" .. perk_data.id

  if include_ui_icon == true then
    perk_data.ui_icon = "mods/kaleva_koetus/files/ui_gfx/perk_icons/" .. encoded_perk_id .. ".png"
  end

  local png_icon_path = "mods/kaleva_koetus/files/items_gfx/perks/" .. encoded_perk_id .. ".png"
  if ModImageDoesExist(png_icon_path) == true then
    perk_data.perk_icon = png_icon_path
  else
    local xml_icon_path = "mods/kaleva_koetus/files/items_gfx/perks/anims/" .. encoded_perk_id .. ".xml"
    if ModDoesFileExist(xml_icon_path) == true then
      perk_data.perk_icon = xml_icon_path
    end
  end
end

---@param perk_data PerkData
local function is_no_remove(perk_data)
  return perk_data.do_not_remove or false
end

---@enum GameEffectField
local game_effects = {
  [1] = "game_effect",
  [2] = "game_effect2",
}

---@param perk_data PerkData
---@return fun():GameEffectField?, string?
local function iterate_game_effect(perk_data)
  local curr = 0
  local total = #game_effects
  return function()
    while curr <= total do
      curr = curr + 1
      local field = game_effects[curr]
      local effect = perk_data[field]
      if effect ~= nil then
        return field, effect
      end
    end
  end
end

---@param entity_who_picked number
---@param start_entity_id number
---@param filter_entity_tag boolean
---@param check_entity fun(entity_id:number):boolean
---@return number[]
local function trace_perk_entity(entity_who_picked, start_entity_id, filter_entity_tag, check_entity)
  local traced_entities = {}
  local child_entities
  if filter_entity_tag == true then
    child_entities = EntityGetAllChildren(entity_who_picked, "perk_entity")
  else
    child_entities = EntityGetAllChildren(entity_who_picked)
  end

  if child_entities == nil then
    return traced_entities
  end

  for _, child_entity_id in ipairs(child_entities) do
    if child_entity_id >= start_entity_id then
      if check_entity(child_entity_id) == true then
        table.insert(traced_entities, child_entity_id)
      end
    end
  end

  return traced_entities
end

local function get_latest_n_entities(entities, target_count)
  table.sort(entities)

  local entity_count = #entities

  if entity_count <= target_count then
    return entities
  end

  local latest_n_entities = {}
  for i = 1, target_count do
    latest_n_entities[i] = entities[i + entity_count - target_count]
  end
  return latest_n_entities
end

---@param game_effect_name string
---@param filter_component_tag boolean
---@return fun(entity_id:number):boolean
local function check_game_effect_component(game_effect_name, filter_component_tag)
  return function(entity_id)
    local game_effect_components
    if filter_component_tag == true then
      game_effect_components = EntityGetComponent(entity_id, "GameEffectComponent", "perk_component")
    else
      game_effect_components = EntityGetComponent(entity_id, "GameEffectComponent")
    end

    if game_effect_components == nil then
      return false
    end

    for _, game_effect_component_id in ipairs(game_effect_components) do
      local effect = ComponentGetValue2(game_effect_component_id, "effect")
      if effect == game_effect_name then
        return true
      end
    end

    return false
  end
end

---@param entity_who_picked number
---@param game_effect_name string
---@param target_count number
---@param start_entity_id number
---@param include_no_remove boolean
---@return number[]
local function trace_perk_effect(entity_who_picked, game_effect_name, target_count, start_entity_id, include_no_remove)
  local traced_entities = trace_perk_entity(
    entity_who_picked,
    start_entity_id,
    not include_no_remove,
    check_game_effect_component(game_effect_name, not include_no_remove)
  )

  return get_latest_n_entities(traced_entities, target_count)
end

---@param ui_name string
---@return fun(entity_id:number):boolean
local function check_ui_icon_component(ui_name)
  return function(entity_id)
    local ui_icon_components = EntityGetComponentIncludingDisabled(entity_id, "UIIconComponent")

    if ui_icon_components == nil then
      return false
    end

    for _, ui_icon_component_id in ipairs(ui_icon_components) do
      local name = ComponentGetValue2(ui_icon_component_id, "name")
      if name == ui_name then
        return true
      end
    end

    return false
  end
end

---@param entity_who_picked number
---@param ui_name string
---@param target_count number
---@param start_entity_id number
---@param include_no_remove boolean
---@return number[]
local function trace_perk_icon(entity_who_picked, ui_name, target_count, start_entity_id, include_no_remove)
  local traced_entities = trace_perk_entity(entity_who_picked, start_entity_id, not include_no_remove, check_ui_icon_component(ui_name))

  return get_latest_n_entities(traced_entities, target_count)
end

---@param entity_id number
local function check_energy_shield(entity_id)
  local energy_shield_component_id = EntityGetFirstComponent(entity_id, "EnergyShieldComponent")

  return energy_shield_component_id ~= nil
end

---@param entity_who_picked number
---@param start_entity_id number
---@return number[]
local function trace_energy_shield(entity_who_picked, start_entity_id)
  return trace_perk_entity(entity_who_picked, start_entity_id, true, check_energy_shield)
end

---@param entity_id number
local function check_area_damage(entity_id)
  local area_damage_component_id = EntityGetFirstComponent(entity_id, "AreaDamageComponent")

  return area_damage_component_id ~= nil
end

---@param entity_who_picked number
---@param start_entity_id number
---@return number[]
local function trace_area_damage_entity(entity_who_picked, start_entity_id)
  return trace_perk_entity(entity_who_picked, start_entity_id, true, check_area_damage)
end

---@param entity_who_picked number
local function pickup_trick_blood_money(entity_who_picked)
  entity_add_variable_tag(entity_who_picked, "kaleva_koetus_trick_blood_money")
end

---@param entity_who_picked number
local function remove_trick_blood_money(entity_who_picked)
  entity_remove_variable_tag(entity_who_picked, "kaleva_koetus_trick_blood_money")
end

---@param entity_who_picked number
---@param kick_component_default_throw_speed number?
local function update_telekinesis(entity_who_picked, kick_component_default_throw_speed)
  local throw_speed = kick_component_default_throw_speed
  local kick_components = EntityGetComponent(entity_who_picked, "KickComponent")
  if kick_components ~= nil then
    for _, kick_componentid in ipairs(kick_components) do
      local telekinesis_throw_speed = ComponentGetValue2(kick_componentid, "telekinesis_throw_speed")
      if throw_speed == nil or telekinesis_throw_speed > throw_speed then
        throw_speed = telekinesis_throw_speed
      end
    end
  end

  if throw_speed == nil then
    return
  end

  throw_speed = throw_speed * 0.5

  local telekinesis_components = EntityGetComponent(entity_who_picked, "TelekinesisComponent")
  if telekinesis_components ~= nil then
    for _, telekinesis_component_id in ipairs(telekinesis_components) do
      ComponentSetValue2(telekinesis_component_id, "throw_speed", throw_speed)

      local max_size = ComponentGetValue2(telekinesis_component_id, "max_size")
      if max_size > 200 then
        ComponentSetValue2(telekinesis_component_id, "max_size", 200)
      end
    end
  end
end

---@param entity_id number
local function remove_saving_grace_restore_entity(entity_id)
  local child_entities = EntityGetAllChildren(entity_id)
  if child_entities == nil then
    return
  end

  for _, child_entity_id in ipairs(child_entities) do
    if entity_has_variable_tag(child_entity_id, "kaleva_koetus_saving_grace_restore") == true then
      local game_effect_components = EntityGetComponent(child_entity_id, "GameEffectComponent")
      if game_effect_components ~= nil then
        for _, game_effect_component_id in ipairs(game_effect_components) do
          local effect = ComponentGetValue2(game_effect_component_id, "effect")
          if effect == "CUSTOM" then
            local custom_effect_id = ComponentGetValue2(game_effect_component_id, "custom_effect_id")
            if custom_effect_id == "SAVING_GRACE_COOLDOWN" then
              ComponentSetValue2(game_effect_component_id, "frames", 0)
              break
            end
          end
        end
      end
    end
  end
end

---@param entity_who_picked number
---@param no_remove boolean
local function pickup_saving_grace(entity_who_picked, no_remove)
  local pickup_count = add_perk_pickup_count(entity_who_picked, "SAVING_GRACE")

  local script_path = "mods/kaleva_koetus/files/scripts/beyonds/b9_saving_grace.lua"

  if pickup_count == 1 then
    local _ = EntityAddComponent2(entity_who_picked, "LuaComponent", {
      _tags = no_remove == false and "perk_component" or nil,
      execute_every_n_frame = -1,
      script_damage_received = script_path,
    })
  elseif pickup_count >= 2 then
    local lua_components = EntityGetComponentIncludingDisabled(entity_who_picked, "LuaComponent")
    if lua_components ~= nil then
      for _, lua_component_id in ipairs(lua_components) do
        local script_damage_received = ComponentGetValue2(lua_component_id, "script_damage_received")
        if script_damage_received == script_path then
          EntityRemoveComponent(entity_who_picked, lua_component_id)
          break
        end
      end
    end

    remove_saving_grace_restore_entity(entity_who_picked)
  end
end

---@param entity_who_picked number
local function remove_saving_grace(entity_who_picked)
  reset_perk_pickup_count(entity_who_picked, "SAVING_GRACE")

  remove_saving_grace_restore_entity(entity_who_picked)
end

---@param entity_who_picked number
local function pickup_remove_fog_of_war(entity_who_picked)
  add_perk_pickup_count(entity_who_picked, "REMOVE_FOG_OF_WAR")
end

---@param entity_who_picked number
local function remove_remove_fog_of_war(entity_who_picked)
  return reset_perk_pickup_count(entity_who_picked, "REMOVE_FOG_OF_WAR")
end

---@param entity_who_picked number
---@param no_remove boolean
local function pickup_invisibility(entity_who_picked, no_remove)
  if entity_has_variable_tag(entity_who_picked, "kaleva_koetus_invisibility") == true then
    return
  end
  entity_add_variable_tag(entity_who_picked, "kaleva_koetus_invisibility")

  local x, y = EntityGetTransform(entity_who_picked)
  local nerf_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/invisibility_nerf_b9.xml", x, y)
  if no_remove == false then
    EntityAddTag(nerf_entity_id, "perk_entity")
  end
  EntityAddChild(entity_who_picked, nerf_entity_id)
end

---@param entity_who_picked number
local function remove_invisibility(entity_who_picked)
  entity_remove_variable_tag(entity_who_picked, "kaleva_koetus_invisibility")
end

---@param entity_who_picked number
---@param no_remove boolean
local function pickup_respawn(entity_who_picked, no_remove)
  local frame_storage_component_id = entity_add_variable_storage(entity_who_picked, "kaleva_koetus_respawn_frame")
  ComponentSetValue2(frame_storage_component_id, "value_int", -1)

  local has_respawn = entity_has_variable_tag(entity_who_picked, "kaleva_koetus_respawn")
  if has_respawn == true then
    return
  end

  reserve_all_respawn_icons(entity_who_picked)

  local script_path = "mods/kaleva_koetus/files/scripts/beyonds/b9_respawn.lua"

  local _ = EntityAddComponent2(entity_who_picked, "LuaComponent", {
    _tags = no_remove == false and "perk_component" or nil,
    execute_every_n_frame = -1,
    script_damage_received = script_path,
  })

  entity_add_variable_tag(entity_who_picked, "kaleva_koetus_respawn")
end

---@param entity_who_picked number
local function remove_respawn(entity_who_picked)
  entity_remove_variable_tag(entity_who_picked, "kaleva_koetus_respawn")
end

---@param game_effect_name string
---@param pickup_tag string
---@param damage_multiplier_field string
---@param damage_multiplier_default number
---@return fun(entity_who_picked:number, no_remove:boolean)
---@return fun(entity_who_picked:number)
local function create_half_protection(game_effect_name, pickup_tag, damage_multiplier_field, damage_multiplier_default)
  local function add_half_protection(entity_who_picked, no_remove)
    if entity_has_variable_tag(entity_who_picked, pickup_tag) == true then
      local effect_component_id, effect_entity_id = GetGameEffectLoadTo(entity_who_picked, game_effect_name, true)
      if effect_component_id ~= 0 then
        ComponentSetValue2(effect_component_id, "frames", -1)
        if no_remove == false then
          ComponentAddTag(effect_component_id, "perk_component")
          EntityAddTag(effect_entity_id, "perk_entity")
        end
      end
      return
    end
    local damage_model_component_id = EntityGetFirstComponent(entity_who_picked, "DamageModelComponent")
    if damage_model_component_id ~= nil then
      local value = ComponentObjectGetValue2(damage_model_component_id, "damage_multipliers", damage_multiplier_field)
      value = value * 0.5
      ComponentObjectSetValue2(damage_model_component_id, "damage_multipliers", damage_multiplier_field, value)
    end
    entity_add_variable_tag(entity_who_picked, pickup_tag)
  end

  local function remove_half_protection(entity_who_picked)
    entity_remove_variable_tag(entity_who_picked, pickup_tag)

    local damage_model_component_id = EntityGetFirstComponent(entity_who_picked, "DamageModelComponent")
    if damage_model_component_id ~= nil then
      ComponentObjectSetValue2(damage_model_component_id, "damage_multipliers", damage_multiplier_field, damage_multiplier_default)
    end
  end

  return add_half_protection, remove_half_protection
end

local add_half_protection_fire, remove_half_protection_fire =
  create_half_protection("PROTECTION_FIRE", "kaleva_koetus_protection_fire", "fire", 1.0)
local add_half_protection_explosion, remove_half_protection_explosion =
  create_half_protection("PROTECTION_EXPLOSION", "kaleva_koetus_protection_explosion", "explosion", 0.35)
local add_half_protection_melee, remove_half_protection_melee =
  create_half_protection("PROTECTION_MELEE", "kaleva_koetus_protection_melee", "melee", 1.0)
local add_half_protection_electricity, remove_half_protection_electricity =
  create_half_protection("PROTECTION_ELECTRICITY", "kaleva_koetus_protection_electricity", "electricity", 1.0)

---@param entity_id number
local function modify_teleportitis(entity_id)
  local game_effect_components = EntityGetComponent(entity_id, "GameEffectComponent")
  if game_effect_components == nil then
    return
  end

  for _, game_effect_component_id in ipairs(game_effect_components) do
    local effect = ComponentGetValue2(game_effect_component_id, "effect")
    if effect == "TELEPORTITIS" then
      local teleportation_radius_min = ComponentGetValue2(game_effect_component_id, "teleportation_radius_min")
      local teleportation_radius_max = ComponentGetValue2(game_effect_component_id, "teleportation_radius_max")

      teleportation_radius_min = teleportation_radius_min * 0.125
      teleportation_radius_max = teleportation_radius_max * 0.1875
      teleportation_radius_max = math.max(teleportation_radius_max, teleportation_radius_min)

      ComponentSetValue2(game_effect_component_id, "teleportation_radius_min", teleportation_radius_min)
      ComponentSetValue2(game_effect_component_id, "teleportation_radius_max", teleportation_radius_max)
    end
  end
end

---@param entity_who_picked number
local function pickup_edit_wands_everywhere(entity_who_picked)
  add_perk_pickup_count(entity_who_picked, "EDIT_WANDS_EVERYWHERE")
end

---@param entity_who_picked number
local function remove_edit_wands_everywhere(entity_who_picked)
  return reset_perk_pickup_count(entity_who_picked, "EDIT_WANDS_EVERYWHERE")
end

---@param entity_who_picked number
local function pickup_wand_experimenter(entity_who_picked)
  if entity_has_variable_tag(entity_who_picked, "kaleva_koetus_wand_experimenter") == true then
    return
  end
  entity_add_variable_tag(entity_who_picked, "kaleva_koetus_wand_experimenter")

  local _ = EntityAddComponent(entity_who_picked, "LuaComponent", {
    _tags = "perk_component",
    script_wand_fired = "mods/kaleva_koetus/files/scripts/beyonds/b9_wand_experimenter.lua",
    execute_every_n_frame = -1,
  })
end

---@param entity_who_picked number
local function remove_wand_experimenter(entity_who_picked)
  entity_remove_variable_tag(entity_who_picked, "kaleva_koetus_wand_experimenter")
end

---@param entity_who_picked number
---@param no_remove boolean
local function pickup_unlimited_spells(entity_who_picked, no_remove)
  local pickup_count = add_perk_pickup_count(entity_who_picked, "UNLIMITED_SPELLS")
  if pickup_count > 1 then
    return
  end

  local _ = EntityAddComponent(entity_who_picked, "ShotEffectComponent", {
    _tags = no_remove == false and "perk_component" or nil,
    extra_modifier = "slow_firing",
  })
end

---@param entity_who_picked number
local function remove_unlimited_spells(entity_who_picked)
  return reset_perk_pickup_count(entity_who_picked, "UNLIMITED_SPELLS")
end

---@param entity_id number
local function nerf_shield(entity_id)
  local energy_shield_components = EntityGetComponent(entity_id, "EnergyShieldComponent")
  if energy_shield_components == nil then
    return
  end

  for _, energy_shield_component_id in ipairs(energy_shield_components) do
    local radius = ComponentGetValue2(energy_shield_component_id, "radius")
    if radius > 2.5 then
      radius = math.max(radius - 2.5, 2.5)
      ComponentSetValue2(energy_shield_component_id, "radius", radius)
    end

    local recharge_speed = ComponentGetValue2(energy_shield_component_id, "recharge_speed")
    if recharge_speed > 0.02 then
      recharge_speed = math.max(recharge_speed - 0.2, 0.02)
      ComponentSetValue2(energy_shield_component_id, "recharge_speed", recharge_speed)
    end
  end
end

---@param entity_id number
local function modify_damage_area_entity(entity_id)
  local script_satisfied
  local lua_components = EntityGetComponent(entity_id, "LuaComponent")
  if lua_components == nil then
    script_satisfied = true
  else
    script_satisfied = false
    for _, lua_component_id in ipairs(lua_components) do
      local script_source_file = ComponentGetValue2(lua_component_id, "script_source_file")
      if script_source_file == "data/scripts/perks/contact_damage.lua" then
        ComponentSetValue2(lua_component_id, "script_source_file", "mods/kaleva_koetus/files/scripts/beyonds/b9_contact_damage.lua")
        script_satisfied = true
        break
      end
    end
  end

  if script_satisfied == false then
    return
  end

  local area_damage_component_id = EntityGetFirstComponent(entity_id, "AreaDamageComponent")
  if area_damage_component_id ~= nil then
    local damage_per_frame = ComponentGetValue2(area_damage_component_id, "damage_per_frame")
    local update_every_n_frame = ComponentGetValue2(area_damage_component_id, "update_every_n_frame")

    damage_per_frame = damage_per_frame * 10
    update_every_n_frame = update_every_n_frame > 0 and update_every_n_frame or 1
    update_every_n_frame = update_every_n_frame * 30

    ComponentSetValue2(area_damage_component_id, "damage_per_frame", damage_per_frame)
    ComponentSetValue2(area_damage_component_id, "update_every_n_frame", update_every_n_frame)
  end
end

---@type table<string, fun(perk_data:PerkData)>
local perk_changes = {
  ["EXTRA_MONEY"] = function(perk_data)
    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "EXTRA_MONEY" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "EXTRA_MONEY", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_extra_money")
      end
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end
  end,
  ["TRICK_BLOOD_MONEY"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_append(entity_who_picked)
      pickup_trick_blood_money(entity_who_picked)
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end

    local function func_remove_prepend(entity_who_picked)
      remove_trick_blood_money(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["MOVEMENT_FASTER"] = function(perk_data)
    local find_effect = false
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "MOVEMENT_FASTER" then
        find_effect = true
        break
      end
    end

    if find_effect == false then
      return
    end

    use_modified_info(perk_data)

    local function func_prepend(entity_who_picked)
      local damage_model_components = EntityGetComponent(entity_who_picked, "DamageModelComponent")
      if damage_model_components == nil then
        return
      end

      for _, damage_model_component_id in ipairs(damage_model_components) do
        local hp = ComponentGetValue2(damage_model_component_id, "hp")
        local max_hp = ComponentGetValue2(damage_model_component_id, "max_hp")

        max_hp = max_hp * 0.75
        max_hp = math.ceil(max_hp * 25) / 25
        hp = math.min(hp, max_hp)

        ComponentSetValue2(damage_model_component_id, "hp", hp)
        ComponentSetValue2(damage_model_component_id, "max_hp", max_hp)
      end
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end
  end,
  ["STRONG_KICK"] = function(perk_data)
    local _func = perk_data.func

    if _func == nil then
      return
    end

    local function func_append(entity_who_picked)
      update_telekinesis(entity_who_picked)
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end
  end,
  ["TELEKINESIS"] = function(perk_data)
    local _func = perk_data.func

    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_append(entity_who_picked)
      update_telekinesis(entity_who_picked, 25)
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end
  end,
  ["SAVING_GRACE"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "SAVING_GRACE" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "SAVING_GRACE", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_saving_grace_effect")
      end
      vm_global.post_pickup(function()
        local icon_entities = trace_perk_icon(entity_who_picked, perk_data.ui_name, 1, vm_global.max_id_before_pickup + 1, no_remove)
        for _, icon_entity_id in ipairs(icon_entities) do
          entity_add_variable_tag(icon_entity_id, "kaleva_koetus_saving_grace_icon")
        end
      end)
      return pickup_saving_grace(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_saving_grace(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["INVISIBILITY"] = function(perk_data)
    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "INVISIBILITY" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "INVISIBILITY", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_invisibility_effect")
      end
      return pickup_invisibility(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_invisibility(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["REMOVE_FOG_OF_WAR"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "REMOVE_FOG_OF_WAR" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "REMOVE_FOG_OF_WAR", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_remove_fog_of_war")
      end
      pickup_remove_fog_of_war(entity_who_picked)
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_remove_fog_of_war(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["EXTRA_HP"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local damage_model_values
    local function func_prepend(entity_who_picked)
      damage_model_values = {}
      local damage_model_components = EntityGetComponent(entity_who_picked, "DamageModelComponent")
      if damage_model_components == nil then
        return
      end
      for _, damage_model_component_id in ipairs(damage_model_components) do
        damage_model_values[damage_model_component_id] = {
          hp = ComponentGetValue2(damage_model_component_id, "hp"),
          max_hp = ComponentGetValue2(damage_model_component_id, "max_hp"),
          max_hp_cap = ComponentGetValue2(damage_model_component_id, "max_hp_cap"),
        }
      end
    end
    local function func_append(entity_who_picked)
      local damage_model_components = EntityGetComponent(entity_who_picked, "DamageModelComponent")
      if damage_model_components ~= nil then
        for _, damage_model_component_id in ipairs(damage_model_components) do
          local old_values = damage_model_values[damage_model_component_id]
          if old_values ~= nil then
            local hp = ComponentGetValue2(damage_model_component_id, "hp")
            local max_hp = ComponentGetValue2(damage_model_component_id, "max_hp")
            local max_hp_cap = ComponentGetValue2(damage_model_component_id, "max_hp_cap")

            if old_values.max_hp_cap > 0 and max_hp_cap > old_values.max_hp_cap then
              max_hp_cap = old_values.max_hp_cap + (max_hp_cap - old_values.max_hp_cap) * 0.5
            end

            if max_hp > old_values.max_hp then
              max_hp = old_values.max_hp + (max_hp - old_values.max_hp) * 0.5
            end
            if max_hp_cap > 0 then
              max_hp = math.min(max_hp, max_hp_cap)
            end

            if hp > old_values.hp then
              hp = old_values.hp + (hp - old_values.hp) * 0.5
            end
            hp = math.min(hp, max_hp)

            ComponentSetValue2(damage_model_component_id, "hp", hp)
            ComponentSetValue2(damage_model_component_id, "max_hp", max_hp)
            ComponentSetValue2(damage_model_component_id, "max_hp_cap", max_hp_cap)
          end
        end
      end
      damage_model_values = nil
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      func_prepend(entity_who_picked)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end
  end,
  ["HEARTS_MORE_EXTRA_HP"] = function(perk_data)
    local _func = perk_data.func

    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_prepend()
      local original_heart_multiplier = tonumber(GlobalsGetValue("kaleva_koetus_original_HEARTS_MORE_EXTRA_HP_MULTIPLIER")) or 1
      GlobalsSetValue("HEARTS_MORE_EXTRA_HP_MULTIPLIER", tostring(original_heart_multiplier))
    end
    local function func_append()
      local original_heart_multiplier = tonumber(GlobalsGetValue("HEARTS_MORE_EXTRA_HP_MULTIPLIER")) or 1
      GlobalsSetValue("kaleva_koetus_original_HEARTS_MORE_EXTRA_HP_MULTIPLIER", tostring(original_heart_multiplier))
      local heart_multiplier
      if original_heart_multiplier > 1 then
        heart_multiplier = 1 + (original_heart_multiplier - 1) * 0.5
      else
        heart_multiplier = original_heart_multiplier
      end
      GlobalsSetValue("HEARTS_MORE_EXTRA_HP_MULTIPLIER", tostring(heart_multiplier))
    end
    local function post_add(...)
      func_append()
      return ...
    end
    perk_data.func = function(...)
      func_prepend()
      return post_add(_func(...))
    end
  end,
  ["RESPAWN"] = function(perk_data)
    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "RESPAWN" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data, false)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities = trace_perk_effect(entity_who_picked, "RESPAWN", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_respawn_effect")
      end
      return vm_global.post_pickup(function()
        local icon_entities = trace_perk_icon(entity_who_picked, perk_data.ui_name, 1, vm_global.max_id_before_pickup + 1, no_remove)
        for _, icon_entity_id in ipairs(icon_entities) do
          entity_add_variable_tag(icon_entity_id, "kaleva_koetus_respawn_icon")
          local is_spent = RespawnIcon.modify_icon_entity(icon_entity_id)
          if is_spent == true then
            entity_add_variable_tag(icon_entity_id, "kaleva_koetus_respawn_spent_icon")
          end
        end
        pickup_respawn(entity_who_picked, no_remove)
      end)
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_respawn(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["FOOD_CLOCK"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["PROTECTION_FIRE"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local change_effect = false
    for field, effect in iterate_game_effect(perk_data) do
      if effect == "PROTECTION_FIRE" then
        perk_data[field] = nil
        change_effect = true
      end
    end

    if change_effect == false then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return add_half_protection_fire(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end

    local function func_remove_append(entity_who_picked)
      return remove_half_protection_fire(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["PROTECTION_EXPLOSION"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local change_effect = false
    for field, effect in iterate_game_effect(perk_data) do
      if effect == "PROTECTION_EXPLOSION" then
        perk_data[field] = nil
        change_effect = true
      end
    end

    if change_effect == false then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return add_half_protection_explosion(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end

    local function func_remove_append(entity_who_picked)
      return remove_half_protection_explosion(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["PROTECTION_MELEE"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local change_effect = false
    for field, effect in iterate_game_effect(perk_data) do
      if effect == "PROTECTION_MELEE" then
        perk_data[field] = nil
        change_effect = true
      end
    end

    if change_effect == false then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return add_half_protection_melee(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end

    local function func_remove_append(entity_who_picked)
      return remove_half_protection_melee(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["PROTECTION_ELECTRICITY"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local change_effect = false
    for field, effect in iterate_game_effect(perk_data) do
      if effect == "PROTECTION_ELECTRICITY" then
        perk_data[field] = nil
        change_effect = true
      end
    end

    if change_effect == false then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return add_half_protection_electricity(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end

    local function func_remove_append(entity_who_picked)
      return remove_half_protection_electricity(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["TELEPORTITIS"] = function(perk_data)
    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "TELEPORTITIS" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "TELEPORTITIS", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        modify_teleportitis(effect_entity_id)
      end
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end
  end,
  ["EDIT_WANDS_EVERYWHERE"] = function(perk_data)
    enable_stackable(perk_data)
    ensure_stackable_maximum(perk_data, 2)

    local effect_count = 0
    for _field, effect in iterate_game_effect(perk_data) do
      if effect == "EDIT_WANDS_EVERYWHERE" then
        effect_count = effect_count + 1
      end
    end

    if effect_count <= 0 then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_append(entity_who_picked)
      local effect_entities =
        trace_perk_effect(entity_who_picked, "EDIT_WANDS_EVERYWHERE", effect_count, vm_global.max_id_before_pickup + 1, no_remove)
      for _, effect_entity_id in ipairs(effect_entities) do
        entity_add_variable_tag(effect_entity_id, "kaleva_koetus_edit_wands_everywhere")
      end
      pickup_edit_wands_everywhere(entity_who_picked)
    end
    local _func = perk_data.func
    if _func ~= nil then
      local function post_add(entity_who_picked, ...)
        func_append(entity_who_picked)
        return ...
      end
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_append(entity_who_picked)
      end
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_edit_wands_everywhere(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["WAND_EXPERIMENTER"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_prepend(entity_who_picked)
      return pickup_wand_experimenter(entity_who_picked)
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      func_prepend(entity_who_picked)
      return _func(entity_perk_item, entity_who_picked, ...)
    end

    local function func_remove_append(entity_who_picked)
      return remove_wand_experimenter(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["PROJECTILE_HOMING_SHOOTER"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["UNLIMITED_SPELLS"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return pickup_unlimited_spells(entity_who_picked, no_remove)
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      func_prepend(entity_who_picked)
      return _func(entity_perk_item, entity_who_picked, ...)
    end

    local function func_remove_prepend(entity_who_picked)
      return remove_unlimited_spells(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      perk_data.func_remove = function(entity_who_picked, ...)
        func_remove_prepend(entity_who_picked)
        return _func_remove(entity_who_picked, ...)
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_prepend(entity_who_picked)
      end
    end
  end,
  ["FREEZE_FIELD"] = function(perk_data)
    local change_effect = false
    for field, effect in iterate_game_effect(perk_data) do
      if effect == "PROTECTION_FIRE" then
        perk_data[field] = nil
        change_effect = true
      end
    end

    if change_effect == false then
      return
    end

    use_modified_info(perk_data)

    local no_remove = is_no_remove(perk_data)

    local function func_prepend(entity_who_picked)
      return add_half_protection_fire(entity_who_picked, no_remove)
    end
    local _func = perk_data.func
    if _func ~= nil then
      perk_data.func = function(entity_perk_item, entity_who_picked, ...)
        func_prepend(entity_who_picked)
        return _func(entity_perk_item, entity_who_picked, ...)
      end
    else
      perk_data.func = function(_entity_perk_item, entity_who_picked)
        return func_prepend(entity_who_picked)
      end
    end

    local function func_remove_append(entity_who_picked)
      return remove_half_protection_fire(entity_who_picked)
    end
    local _func_remove = perk_data.func_remove
    if _func_remove ~= nil then
      local function post_remove(entity_who_picked, ...)
        func_remove_append(entity_who_picked)
        return ...
      end
      perk_data.func_remove = function(entity_who_picked, ...)
        return post_remove(entity_who_picked, _func_remove(entity_who_picked, ...))
      end
    else
      perk_data.func_remove = function(entity_who_picked)
        return func_remove_append(entity_who_picked)
      end
    end
  end,
  ["SHIELD"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_append(entity_who_picked)
      local shield_entities = trace_energy_shield(entity_who_picked, vm_global.max_id_before_pickup + 1)
      for _, shield_entity_id in ipairs(shield_entities) do
        nerf_shield(shield_entity_id)
      end
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end
  end,
  ["RISKY_CRITICAL"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["LOWER_SPREAD"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["NO_MORE_SHUFFLE"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["CONTACT_DAMAGE"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_append(entity_who_picked)
      local area_damage_entities = trace_area_damage_entity(entity_who_picked, vm_global.max_id_before_pickup + 1)
      for _, area_damage_entity_id in ipairs(area_damage_entities) do
        modify_damage_area_entity(area_damage_entity_id)
      end
    end
    local function post_add(entity_who_picked, ...)
      func_append(entity_who_picked)
      return ...
    end
    perk_data.func = function(entity_perk_item, entity_who_picked, ...)
      return post_add(entity_who_picked, _func(entity_perk_item, entity_who_picked, ...))
    end
  end,
  ["EXTRA_PERK"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)
  end,
  ["PERKS_LOTTERY"] = function(perk_data)
    local _func = perk_data.func
    if _func == nil then
      return
    end

    use_modified_info(perk_data)

    local function func_prepend()
      local original_perk_destroy_chance = tonumber(GlobalsGetValue("kaleva_koetus_original_TEMPLE_PERK_DESTROY_CHANCE")) or 100
      GlobalsSetValue("TEMPLE_PERK_DESTROY_CHANCE", tostring(original_perk_destroy_chance))
    end
    local function func_append()
      local original_perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE")) or 100
      GlobalsSetValue("kaleva_koetus_original_TEMPLE_PERK_DESTROY_CHANCE", tostring(original_perk_destroy_chance))
      local perk_destroy_chance = (original_perk_destroy_chance / 100) ^ 0.4 * 100
      GlobalsSetValue("TEMPLE_PERK_DESTROY_CHANCE", tostring(perk_destroy_chance))
    end
    local function post_add(...)
      func_append()
      return ...
    end
    perk_data.func = function(...)
      func_prepend()
      return post_add(_func(...))
    end
  end,
}
perk_changes["EXPLODING_CORPSES"] = perk_changes["PROTECTION_EXPLOSION"]
perk_changes["BLEED_OIL"] = perk_changes["PROTECTION_FIRE"]

-- selene: allow(undefined_variable)
for _, perk_data in ipairs(perk_list) do
  ---@cast perk_data PerkData
  local change_func = perk_changes[perk_data.id]
  if change_func ~= nil then
    change_func(perk_data)
  end
end
