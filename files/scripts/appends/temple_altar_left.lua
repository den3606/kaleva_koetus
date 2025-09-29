local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local AscensionTags = EventDefs.Tags

local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("temple_altar_left.lua")

local _init = init
-- selene: allow(unused_variable)
function init(x, y, w, h)
  local activate_a12 = GlobalsGetValue(AscensionTags.A12 .. "override_pixel_scene", "0") == "1"
  if activate_a12 then
    log:info("a12 temple_left override")
    -- selene: allow(undefined_variable)
    spawn_altar_top(x, y, false)
    LoadPixelScene(
      "mods/kaleva_koetus/files/biome_impl/temple/altar_left.png",
      "data/biome_impl/temple/altar_left_visual.png",
      x,
      y - 40 + 300,
      "data/biome_impl/temple/altar_left_background.png",
      true
    )
  else
    _init(x, y, w, h)
  end
end
