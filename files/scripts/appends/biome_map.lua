-- selene: allow(undefined_variable)
local bit = bit

local width, height = BiomeMapGetSize()
local function replace_color(color_to_replace, new_biome_color, on_replace)
  for y = 0, height - 1 do
    for x = 0, width - 1 do
      if bit.bxor(BiomeMapGetPixel(x, y), color_to_replace) == 0 then
        if on_replace == nil or on_replace(x, y) then
          BiomeMapSetPixel(x, y, new_biome_color)
        end
      end
    end
  end
end

local biome_boss_victoryroom = 0xffd7ee50
local biome_lava = 0xffFF6A02
local biome_solid_wall_temple = 0xff28A9B8

local victoryroom_pixels = {}
local function get_victoryroom(x, y)
  table.insert(victoryroom_pixels, { x, y })
  return true
end
replace_color(biome_boss_victoryroom, biome_lava, get_victoryroom)

local function check_around_victoryroom(x, y)
  for _, pos in ipairs(victoryroom_pixels) do
    if x >= pos[1] - 1 and x <= pos[1] + 1 and y >= pos[2] - 1 and y <= pos[2] + 1 then
      return true
    end
  end
  return false
end
replace_color(biome_solid_wall_temple, biome_lava, check_around_victoryroom)
