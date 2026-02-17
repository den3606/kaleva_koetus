---@type path32
local path32 = dofile_once("mods/kaleva_koetus/files/scripts/lib/path32.lua")

---@class RespawnIcon
local RespawnIcon = {}

---@param entity_id number
---@return boolean is_spent
function RespawnIcon.modify_icon_entity(entity_id)
  local ui_icon_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "UIIconComponent")
  if ui_icon_component_id == nil then
    return false
  end

  local icon_sprite_file = ComponentGetValue2(ui_icon_component_id, "icon_sprite_file")
  if icon_sprite_file == "data/ui_gfx/perk_icons/respawn.png" then
    ComponentSetValue2(
      ui_icon_component_id,
      "icon_sprite_file",
      "mods/kaleva_koetus/files/ui_gfx/perk_icons/" .. path32.encode("RESPAWN") .. ".png"
    )
  elseif icon_sprite_file == "data/ui_gfx/perk_icons/respawn_spent.png" then
    ComponentSetValue2(
      ui_icon_component_id,
      "icon_sprite_file",
      "mods/kaleva_koetus/files/ui_gfx/perk_icons/" .. path32.encode("RESPAWN_spent") .. ".png"
    )
    ComponentSetValue2(ui_icon_component_id, "name", "$kaleva_koetus_perk_RESPAWN_spent")
    ComponentSetValue2(ui_icon_component_id, "description", "$kaleva_koetus_perkdesc_RESPAWN_spent")
    return true
  end

  return false
end

---@param entity_id number
---@return boolean is_spent
function RespawnIcon.reset_icon_entity(entity_id)
  local ui_icon_component_id = EntityGetFirstComponentIncludingDisabled(entity_id, "UIIconComponent")
  if ui_icon_component_id == nil then
    return false
  end

  local icon_sprite_file = ComponentGetValue2(ui_icon_component_id, "icon_sprite_file")
  if icon_sprite_file == "data/ui_gfx/perk_icons/respawn.png" then
    return false
  end
  if icon_sprite_file == "data/ui_gfx/perk_icons/respawn_spent.png" then
    return true
  end

  ComponentSetValue2(ui_icon_component_id, "icon_sprite_file", "data/ui_gfx/perk_icons/respawn.png")
  return false
end

return RespawnIcon
