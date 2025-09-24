local ImageEditor = {}

function ImageEditor:override_image(target_image_path, source_image_path)
  local target_image, target_width, target_height = ModImageMakeEditable(source_image_path, 0, 0)
  local source_image, source_width, source_height = ModImageMakeEditable(target_image_path, 0, 0)

  if target_width == 0 or target_height == 0 or source_width == 0 or source_height == 0 then
    error("[Kaleva Koetus] One of the image sizes is 0px")
  end

  if target_width ~= source_width or target_height ~= source_height then
    error("[Kaleva Koetus] These image size are not same size")
  end

  for i = 0, target_width, 1 do
    for j = 0, target_height, 1 do
      ModImageSetPixel(target_image, i, j, ModImageGetPixel(source_image, i, j))
    end
  end
end

return ImageEditor
