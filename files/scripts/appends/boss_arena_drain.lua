---@param area_x number
---@param area_y number
---@param area_w number
---@param area_h number
---@param material_from_type number
---@param material_to_type number
---@param trim_box2d boolean
---@param update_edge_graphics_dummy boolean
local function ConvertMaterialOnAreaInstantly_Workaround(
  area_x,
  area_y,
  area_w,
  area_h,
  material_from_type,
  material_to_type,
  trim_box2d,
  update_edge_graphics_dummy
)
  if area_w <= 0 then
    return
  end

  while area_h > area_w do
    ConvertMaterialOnAreaInstantly(
      area_x,
      area_y,
      area_w,
      area_w,
      material_from_type,
      material_to_type,
      trim_box2d,
      update_edge_graphics_dummy
    )
    area_y = area_y + area_w
    area_h = area_h - area_w
  end

  ConvertMaterialOnAreaInstantly(
    area_x,
    area_y,
    area_w,
    area_h,
    material_from_type,
    material_to_type,
    trim_box2d,
    update_edge_graphics_dummy
  )
end

-- selene: allow(undefined_variable)
local _spawn_areachecks_left = spawn_areachecks_left
-- selene: allow(unused_variable)
function spawn_areachecks_left(x, y)
  _spawn_areachecks_left(x, y)
  local mat_water = CellFactory_GetType("water")
  local mat_mud = CellFactory_GetType("mud")
  local mat_air = CellFactory_GetType("air")
  -- x = 1919
  -- y = 13131
  ConvertMaterialOnAreaInstantly_Workaround(x + 102, y + 42, 27, 91, mat_water, mat_air, true, false)
  ConvertMaterialOnAreaInstantly_Workaround(x + 102, y + 42, 27, 91, mat_mud, mat_air, true, false)
  -- x + 102 = 2021
  -- 2021 + 27 - 1 = 2047
  -- y + 42 = 13173
  -- 13173 + 91 - 1 = 13263
end

-- selene: allow(undefined_variable)
local _spawn_areachecks_right = spawn_areachecks_right
-- selene: allow(unused_variable)
function spawn_areachecks_right(x, y)
  _spawn_areachecks_right(x, y)
  local mat_water = CellFactory_GetType("water")
  local mat_mud = CellFactory_GetType("mud")
  local mat_air = CellFactory_GetType("air")
  -- x = 2331
  -- y = 13131
  ConvertMaterialOnAreaInstantly_Workaround(x - 283, y + 42, 37, 91, mat_water, mat_air, true, false)
  ConvertMaterialOnAreaInstantly_Workaround(x - 283, y + 42, 37, 91, mat_mud, mat_air, true, false)
  -- x - 283 = 2048
  -- 2048 + 37 - 1 = 2084
  ConvertMaterialOnAreaInstantly_Workaround(x - 190, y + 42, 63, 67, mat_water, mat_air, true, false)
  ConvertMaterialOnAreaInstantly_Workaround(x - 162, y + 109, 35, 1, mat_water, mat_air, true, false)
  ConvertMaterialOnAreaInstantly_Workaround(x - 190, y + 42, 63, 91, mat_mud, mat_air, true, false)
  -- x - 190 = 2141
  -- 42 + 67 = 109
  -- -190 + 63 = -162 + 35
  -- x + 63 - 1 = 2203
end
