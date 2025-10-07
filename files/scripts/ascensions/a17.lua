-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a17.lua")

ascension.level = 17
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A16 .. "dummy"

function ascension:on_activate()
  -- log:info("follow bird")

  local target_images = {
    "data/particles/radar_enemy_faint.png",
    "data/particles/radar_enemy_medium.png",
    "data/particles/radar_enemy_strong.png",
    "data/enemies_gfx/ultimate_killer.png",
  }

  for _, image in ipairs(target_images) do
    local id, x, y = ModImageMakeEditable(image, 0, 0)
    local a17_id = ModImageMakeEditable("mods/kaleva_koetus/tmp/a17/" .. image, x, y)
    for i = 0, x, 1 do
      for j = 0, y, 1 do
        local color = ModImageGetPixel(id, i, j)
        local inverted = ImageEditor:invert_hue_abgr(color)
        ModImageSetPixel(a17_id, i, j, inverted)
      end
    end
  end

  for content in nxml.edit_file("data/entities/animals/boss_centipede/sampo.xml") do
    content:create_child(
      "LuaComponent",
      { script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a17_sampo_pickup_option.lua", execute_every_n_frame = "10" }
    )
  end
end

function ascension:on_player_spawn(player_entity_id)
  local friend_not_spawned = GlobalsGetValue("kaleva_koetus.a17_friend_not_spawned", "true") == "true"
  if friend_not_spawned then
    local x, y = EntityGetTransform(player_entity_id)
    local _ = EntityAddComponent2(player_entity_id, "LuaComponent", {
      script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a17_friend_radar.lua",
      execute_every_n_frame = 1,
    })
    local friend_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/following_friend.xml", x, y)
    EntityAddTag(friend_entity_id, "kk_a17_friend")
    local _ = EntityAddComponent2(friend_entity_id, "VariableStorageComponent", {
      name = "owner_id",
      value_int = player_entity_id,
    })
    local _ = EntityAddComponent2(player_entity_id, "LuaComponent", {
      script_portal_teleport_used = "mods/kaleva_koetus/files/scripts/ascensions/a17_player_portal_teleported.lua",
      execute_every_n_frame = -1,
    })
    local _ = EntityAddComponent2(player_entity_id, "LuaComponent", {
      script_teleported = "mods/kaleva_koetus/files/scripts/ascensions/a17_player_portal_teleported.lua",
      execute_every_n_frame = -1,
    })
    GlobalsSetValue("kaleva_koetus.a17_friend_not_spawned", "false")
  end
end

return ascension
