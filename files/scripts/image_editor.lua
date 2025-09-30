local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local log = Logger:new("image_editor.lua")

local ImageEditor = {}

-- ABGR(0xAABBGGRR) を分解
local function abgr_to_rgba(c)
  local a = math.floor(c / 0x1000000) % 0x100
  local b = math.floor(c / 0x0010000) % 0x100
  local g = math.floor(c / 0x0000100) % 0x100
  local r = c % 0x100
  return r, g, b, a
end

local function rgba_to_abgr(r, g, b, a)
  return a * 0x1000000 + b * 0x0010000 + g * 0x0000100 + r
end

-- 色相反転
local function invert_hue_rgb(r, g, b)
  local R, G, B = r / 255, g / 255, b / 255
  local maxc = math.max(R, G, B)
  local minc = math.min(R, G, B)
  local L = (maxc + minc) / 2
  local H, S

  if maxc == minc then
    H, S = 0, 0
  else
    local d = maxc - minc
    S = (L > 0.5) and (d / (2 - maxc - minc)) or (d / (maxc + minc))
    if maxc == R then
      H = (G - B) / d + (G < B and 6 or 0)
    elseif maxc == G then
      H = (B - R) / d + 2
    else
      H = (R - G) / d + 4
    end
    H = H / 6
  end

  H = (H + 0.5) % 1.0

  local function hue_to_rgb(p, q, t)
    if t < 0 then
      t = t + 1
    end
    if t > 1 then
      t = t - 1
    end
    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    end
    if t < 1 / 2 then
      return q
    end
    if t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end
    return p
  end

  local r2, g2, b2
  if S == 0 then
    r2, g2, b2 = L, L, L
  else
    local q = (L < 0.5) and (L * (1 + S)) or (L + S - L * S)
    local p = 2 * L - q
    r2 = hue_to_rgb(p, q, H + 1 / 3)
    g2 = hue_to_rgb(p, q, H)
    b2 = hue_to_rgb(p, q, H - 1 / 3)
  end

  return math.floor(r2 * 255 + 0.5), math.floor(g2 * 255 + 0.5), math.floor(b2 * 255 + 0.5)
end

--- @param color_abgr
--- @return color_abgr
function ImageEditor:invert_hue_abgr(color_abgr)
  local r, g, b, a = abgr_to_rgba(color_abgr)
  local r2, g2, b2 = invert_hue_rgb(r, g, b)
  return rgba_to_abgr(r2, g2, b2, a)
end

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
