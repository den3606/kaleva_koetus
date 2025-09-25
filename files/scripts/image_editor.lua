local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("image_editor.lua")

local ImageEditor = {}

function ImageEditor:override_image(target_image_path, override_image_path)
  local target_image, target_width, target_height = ModImageMakeEditable(target_image_path, 0, 0)
  local override_image, override_width, override_height = ModImageMakeEditable(override_image_path, 0, 0)

  if target_image == 0 or override_image == 0 then
    log:error("The target or source file are not initialized. Use ModImageMakeEditable")
  end

  if target_width == 0 or target_height == 0 or override_width == 0 or override_height == 0 then
    log:error("One of the image sizes is 0px")
  end

  if target_width ~= override_width or target_height ~= override_height then
    log:error("These image size are not same size")
  end

  for i = 0, target_width, 1 do
    for j = 0, target_height, 1 do
      ModImageSetPixel(target_image, i, j, ModImageGetPixel(override_image, i, j))
    end
  end
end

return ImageEditor
