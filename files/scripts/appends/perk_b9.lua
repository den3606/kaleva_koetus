local vm_global = dofile_once("mods/kaleva_koetus/files/scripts/vm_global.lua")

vm_global.max_id_before_pickup = vm_global.max_id_before_pickup or 0

---@type function[]
local post_pickup_funcs = {}

---@param post_pickup_func function
vm_global.post_pickup = function(post_pickup_func)
  table.insert(post_pickup_funcs, post_pickup_func)
end

local function post_pickup(...)
  if #post_pickup_funcs > 0 then
    for _, post_pickup_func in ipairs(post_pickup_funcs) do
      post_pickup_func()
    end
    post_pickup_funcs = {}
  end
  return ...
end

-- selene: allow(undefined_variable)
local _perk_pickup = perk_pickup
-- selene: allow(unused_variable)
function perk_pickup(...)
  vm_global.max_id_before_pickup = EntitiesGetMaxID()
  return post_pickup(_perk_pickup(...))
end

local BASE_PERK_COUNT = 2
local EXTRA_PERK_RATIO = 0.5

local random_round

local GlobalsGetValue_original = GlobalsGetValue
local function GlobalsGetValue_modified(key, ...)
  if key ~= "TEMPLE_PERK_COUNT" then
    return GlobalsGetValue_original(key, ...)
  end

  local base_perk_count = tonumber(GlobalsGetValue_original("kaleva_koetus_base_TEMPLE_PERK_COUNT")) or BASE_PERK_COUNT
  local perk_count = tonumber(GlobalsGetValue_original("TEMPLE_PERK_COUNT")) or 3

  perk_count = base_perk_count + (perk_count - base_perk_count) * EXTRA_PERK_RATIO
  perk_count = math.floor(perk_count + random_round)

  return tostring(perk_count)
end

local function post_perk_spawn_many(...)
  -- selene: allow(incorrect_standard_library_use)
  GlobalsGetValue = GlobalsGetValue_original
  return ...
end

-- selene: allow(undefined_variable)
local _perk_spawn_many = perk_spawn_many
-- selene: allow(unused_variable)
function perk_spawn_many(x, y, ...)
  random_round = ProceduralRandomf(x + 200, y + 900)
  -- selene: allow(incorrect_standard_library_use)
  GlobalsGetValue = GlobalsGetValue_modified
  return post_perk_spawn_many(_perk_spawn_many(x, y, ...))
end
