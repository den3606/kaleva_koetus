local function generate_item_with_price(item, x, y, base_price)
  local biomes = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 1,
    [5] = 1,
    [6] = 1,
    [7] = 2,
    [8] = 2,
    [9] = 2,
    [10] = 2,
    [11] = 2,
    [12] = 2,
    [13] = 3,
    [14] = 3,
    [15] = 3,
    [16] = 3,
    [17] = 4,
    [18] = 4,
    [19] = 4,
    [20] = 4,
    [21] = 5,
    [22] = 5,
    [23] = 5,
    [24] = 5,
    [25] = 6,
    [26] = 6,
    [27] = 6,
    [28] = 6,
    [29] = 6,
    [30] = 6,
    [31] = 6,
    [32] = 6,
    [33] = 6,
  }

  local biomepixel = math.floor(y / 512)
  local biomeid = biomes[biomepixel] or 0

  if biomepixel > 35 then
    biomeid = 7
  end

  biomeid = biomeid * biomeid

  local price = math.max(math.floor((base_price * 0.30 + 70 * biomeid) / 10) * 10, 10)

  if biomeid >= 10 then
    price = price * 5.0
  end

  local eid = EntityLoad(item, x, y)

  local item_component_id = EntityGetFirstComponent(eid, "ItemComponent")
  if item_component_id ~= nil then
    ComponentSetValue2(item_component_id, "auto_pickup", false)
  end

  local offsetx = 6
  local text = tostring(price)
  local textwidth = 0

  for i = 1, #text do
    local l = string.sub(text, i, i)

    if l ~= "1" then
      textwidth = textwidth + 6
    else
      textwidth = textwidth + 3
    end
  end

  offsetx = textwidth * 0.5 - 0.5

  local _ = EntityAddComponent2(eid, "SpriteComponent", {
    _tags = "shop_cost,enabled_in_world",
    image_file = "data/fonts/font_pixel_white.xml",
    is_text_sprite = true,
    offset_x = offsetx,
    offset_y = 25,
    update_transform = true,
    update_transform_rotation = false,
    text = text,
    z_index = -1,
  })

  _ = EntityAddComponent2(eid, "ItemCostComponent", {
    _tags = "shop_cost,enabled_in_world",
    cost = price,
    stealable = true,
  })

  _ = EntityAddComponent2(eid, "LuaComponent", {
    script_item_picked_up = "data/scripts/items/shop_effect.lua",
  })

  return eid
end

return generate_item_with_price
