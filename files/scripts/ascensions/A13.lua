local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 13
ascension.name = "きのこシフト"
ascension.description = "開始時にきのこシフトが発生"

ascension._shift_triggered = false

local function call_fungal_shift(player_entity_id)
  local x, y = EntityGetTransform(player_entity_id)
  local ok, result = pcall(dofile, "data/scripts/magic/fungal_shift.lua")
  if not ok then
    print("[Kaleva Koetus A13] Failed to load fungal_shift.lua: " .. tostring(result))
    return
  end

  local shift_fn = result
  if type(result) == "table" then
    shift_fn = result.fungal_shift or result[1]
  end

  if type(shift_fn) ~= "function" then
    print("[Kaleva Koetus A13] fungal_shift.lua did not return a callable function")
    return
  end

  local success, err = pcall(shift_fn, player_entity_id, x, y)
  if not success then
    print("[Kaleva Koetus A13] fungal_shift invocation failed: " .. tostring(err))
  end
end

function ascension:on_activate()
  print("[Kaleva Koetus A13] Fungal shift scheduled on spawn")
end

function ascension:on_player_spawn(player_entity_id)
  if self._shift_triggered then
    return
  end

  call_fungal_shift(player_entity_id)
  GamePrint("The air shimmers... a fungal shift occurs!")
  self._shift_triggered = true
end

return ascension
