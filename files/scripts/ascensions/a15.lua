local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

local AscensionTags = EventDefs.Tags
local EventTypes = EventDefs.Types
local log = Logger:new("a15.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

ascension.level = 15
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A15 .. EventTypes.SPELL_GENERATED

local function addr_seed_from_table(t)
  local s = tostring(t or {})
  local hex = s:match("0x(%x+)") or s:match("(%x+)$") or "0"
  local n = tonumber(hex, 16) or 0

  -- 32bitに畳んで拡散（軽いミックス）
  -- n >> 16 を算術演算で実装
  local shift = math.floor(n / 65536)

  -- n ^ (n >> 16) のXORを算術演算で実装
  local xor_result = 0
  local a, b = n, shift
  for i = 0, 31 do
    local bit_val = 2 ^ i
    local bit_a = math.floor(a / bit_val) % 2
    local bit_b = math.floor(b / bit_val) % 2
    if bit_a ~= bit_b then
      xor_result = xor_result + bit_val
    end
  end

  -- 乗算して32bitマスク
  n = (xor_result * 0x45d9f3b) % 4294967296

  return n
end

local function random_unique_integers(min, max, count)
  local numbers = {}
  for i = min, max do
    table.insert(numbers, i)
  end

  -- Fisher-Yates shuffle
  for i = #numbers, 2, -1 do
    local j = math.random(1, i)
    numbers[i], numbers[j] = numbers[j], numbers[i]
  end

  local result = {}
  for i = 1, count do
    table.insert(result, numbers[i])
  end

  return result
end

function ascension:on_activate()
  log:info("Broken spells")
end

function ascension:on_mod_post_init()
  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions
  local _, _, _, _, minute, second = GameGetDateAndTimeUTC()
  math.randomseed(addr_seed_from_table() + minute + second)

  local target_indexes = random_unique_integers(1, #actions, math.floor(#actions / 2))
  for _, index in ipairs(target_indexes) do
    local id, x, y = ModImageMakeEditable(actions[index].sprite, 0, 0)
    -- NOTE:
    -- ダミーの画像参照を作って、gun_actions側で対象画像かを判別できるようにする
    local _ = ModImageMakeEditable("kk/a15/" .. actions[index].sprite, 1, 1)

    for i = 0, x, 1 do
      for j = 0, y, 1 do
        local color = ModImageGetPixel(id, i, j)
        local inverted = ImageEditor:invert_hue_abgr(color)
        ModImageSetPixel(id, i, j, inverted)
      end
    end
  end

  ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/kaleva_koetus/files/scripts/appends/gun_actions.lua")
end

local function rename_spell(spell_entity_id)
  local _ = dofile_once("data/scripts/gun/gun_actions.lua")
  -- selene: allow(undefined_variable)
  local actions = actions
  local item_action_component_id = EntityGetFirstComponentIncludingDisabled(spell_entity_id, "ItemActionComponent")
  local action_id = ComponentGetValue2(item_action_component_id, "action_id")

  local ability_component_id = EntityGetFirstComponentIncludingDisabled(spell_entity_id, "AbilityComponent")

  if ability_component_id and action_id then
    for _, action in ipairs(actions) do
      if action.id == action_id then
        local action_name = GameTextGetTranslatedOrNot("$kaleva_koetus_broken_spell") .. GameTextGetTranslatedOrNot(action.name)
        ComponentSetValue2(ability_component_id, "ui_name", action_name)
      end
    end
  end
end

function ascension:on_spell_generated(payload)
  local spell_entity_id = tonumber(payload[1])

  if not spell_entity_id or spell_entity_id == 0 or EntityHasTag(spell_entity_id, ascension.tag_name) then
    return
  end

  rename_spell(spell_entity_id)
end

return ascension
