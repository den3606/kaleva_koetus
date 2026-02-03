local status_effects_append = {
  {
    id = "INCOMPLETE_MOVEMENT_FASTER_2X",
    ui_name = "$kaleva_koetus_b7_status_movement_faster",
    ui_description = "$kaleva_koetus_b7_statusdesc_movement_faster",
    ui_icon = "mods/kaleva_koetus/b7/data/ui_gfx/status_indicators/movement_faster.png",
    effect_entity = "mods/kaleva_koetus/files/entities/misc/effect_movement_faster_2x_b7.xml",
  },
  {
    id = "INCOMPLETE_PROTECTION_ALL",
    ui_name = "$kaleva_koetus_b7_status_protection_all",
    ui_description = "$kaleva_koetus_b7_statusdesc_protection_all",
    ui_icon = "mods/kaleva_koetus/b7/data/ui_gfx/status_indicators/protection_all.png",
    effect_entity = "mods/kaleva_koetus/files/entities/misc/effect_protection_all_b7.xml",
  },
  {
    id = "INCOMPLETE_UNSTABLE_TELEPORTATION",
    ui_name = "$kaleva_koetus_b7_status_teleportation",
    ui_description = "$kaleva_koetus_b7_statusdesc_teleportation",
    ui_icon = "mods/kaleva_koetus/b7/data/ui_gfx/status_indicators/teleportation.png",
    effect_entity = "mods/kaleva_koetus/files/entities/misc/effect_unstable_teleportation_b7.xml",
    is_harmful = true,
  },
  {
    id = "INCOMPLETE_TELEPORTATION",
    ui_name = "$kaleva_koetus_b7_status_teleportation",
    ui_description = "$kaleva_koetus_b7_statusdesc_teleportation",
    ui_icon = "mods/kaleva_koetus/b7/data/ui_gfx/status_indicators/teleportation.png",
    effect_entity = "mods/kaleva_koetus/files/entities/misc/effect_teleportation_b7.xml",
    is_harmful = true,
  },
}

for _, v in ipairs(status_effects_append) do
  -- selene: allow(undefined_variable)
  table.insert(status_effects, v)
end
