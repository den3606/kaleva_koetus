local entity_id = GetUpdatedEntityID()

local root_entity_id = EntityGetRootEntity(entity_id)
if root_entity_id == entity_id then
  return
end

local effect_component_id = EntityGetFirstComponent(root_entity_id, "LuaComponent", "incomplete_protection_all")
if effect_component_id ~= nil then
  return
end

local _ = EntityAddComponent2(root_entity_id, "LuaComponent", {
  _tags = "incomplete_protection_all",
  script_source_file = "mods/kaleva_koetus/files/scripts/status_effects/incomplete_protection_all_detach.lua",
  execute_every_n_frame = 0,
  script_damage_about_to_be_received = "mods/kaleva_koetus/files/scripts/status_effects/incomplete_protection_all.lua",
})
