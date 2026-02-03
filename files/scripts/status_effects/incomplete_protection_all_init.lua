local entity_id = GetUpdatedEntityID()

local _ = EntityAddComponent2(entity_id, "LuaComponent", {
  script_source_file = "mods/kaleva_koetus/files/scripts/status_effects/incomplete_protection_all_attach.lua",
  execute_every_n_frame = 0,
  remove_after_executed = true,
})
