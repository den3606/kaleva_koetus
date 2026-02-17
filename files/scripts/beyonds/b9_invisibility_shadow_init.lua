local entity_id = GetUpdatedEntityID()

local _ = EntityAddComponent2(entity_id, "LuaComponent", {
  script_source_file = "mods/kaleva_koetus/files/scripts/beyonds/b9_invisibility_shadow_update.lua",
  execute_on_added = true,
  execute_every_n_frame = -1,
  enable_coroutines = true,
  vm_type = "ONE_PER_COMPONENT_INSTANCE",
})
